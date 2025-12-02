package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.client.GptApiClient; // 👈 추가
import cau.team_refrigerator.refrigerator.domain.*;
import cau.team_refrigerator.refrigerator.domain.dto.ChatbotInventoryResponseDto;
import cau.team_refrigerator.refrigerator.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import cau.team_refrigerator.refrigerator.domain.dto.ChatbotInventoryResponseDto;
import cau.team_refrigerator.refrigerator.domain.dto.ChatbotInventoryResponseDto.ItemDetailDto;
import java.time.temporal.ChronoUnit;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class RefrigeratorService {

    private final IngredientRepository ingredientRepository;
    private final ItemRepository itemRepository;
    private final IngredientLogRepository logRepository;
    private final RefrigeratorRepository refrigeratorRepository;
    private final IngredientStaticsRepository ingredientStaticsRepository;

    private final GptApiClient gptApiClient; // 👈 1. GPT 클라이언트 주입

    @Transactional
    public void addIngredient(String ingredientName, LocalDate expiryDate, int quantity,
                              ItemCategory category, User user, RefrigeratorType refrigeratorType) {

        // 1. 사용자의 해당 타입 냉장고 찾기
        List<Refrigerator> userRefrigerators = refrigeratorRepository.findByUser(user);
        Refrigerator targetRefrigerator = userRefrigerators.stream()
                .filter(ref -> ref.getType() == refrigeratorType)
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("해당 유저의 [" + refrigeratorType + "] 타입 냉장고를 찾을 수 없습니다."));

        // 👇👇👇 [추가된 로직] 유통기한이 없으면 GPT에게 물어봐서 자동 채움 👇👇👇
        if (expiryDate == null) {
            try {
                String recommendedDateStr = gptApiClient.recommendExpirationDate(ingredientName);
                expiryDate = LocalDate.parse(recommendedDateStr); // String -> LocalDate 변환
                System.out.println("🤖 GPT 자동 추천 날짜 적용: " + expiryDate);
            } catch (Exception e) {
                System.err.println("날짜 추천 실패, 기본값(7일 후) 적용: " + e.getMessage());
                expiryDate = LocalDate.now().plusDays(7);
            }
        }
        // -------------------------------------------------------------------

        // 2. Item 생성
        Item newItem = Item.builder()
                .name(ingredientName)
                .registrationDate(LocalDate.now())
                .expiryDate(expiryDate) // (GPT가 채워준 날짜 사용)
                .quantity(quantity)
                .category(category)
                .refrigerator(targetRefrigerator)
                .build();

        // 3. Item 저장
        Item savedItem = itemRepository.save(newItem);

        // 4. Ingredient 테이블에도 이름 등록
        findOrCreateIngredient(ingredientName);

        // 5. 로그 및 통계 저장
        IngredientLog log = new IngredientLog(savedItem, user);
        logRepository.save(log);
        IngredientStatics stat = ingredientStaticsRepository.findById(savedItem.getId())
                .orElseGet(() -> new IngredientStatics(savedItem));
        stat.incrementCount();
        ingredientStaticsRepository.save(stat);
    }

    private Ingredient findOrCreateIngredient(String name) {
        String trimmedName = name.trim();
        return ingredientRepository.findByName(trimmedName)
                .orElseGet(() -> {
                    System.out.println("냉장고 추가 시 새로운 재료 발견 및 저장: " + trimmedName);
                    return ingredientRepository.save(Ingredient.builder().name(trimmedName).build());
                });
    }

    @Transactional(readOnly = true)
    public List<String> getExpiringIngredientNames(User user, int daysLimit) {
        LocalDate targetDate = LocalDate.now().plusDays(daysLimit);
        List<String> result = itemRepository.findNamesByUserIdAndExpiringBefore(user.getId(), targetDate);
        System.out.println(">> [서비스] 유통기한 임박(" + targetDate + "까지) 재료 발견: " + result);
        return result;
    }
    /**
     * [신규] 임박 재료 조회 후 챗봇 응답 포맷으로 변환
     */
    @Transactional(readOnly = true)
    public ChatbotInventoryResponseDto getExpiringItemsForChatbot(User user, int daysLimit) {

        LocalDate today = LocalDate.now();               // 시작일: 오늘
        LocalDate targetDate = today.plusDays(daysLimit); // 종료일: 오늘 + 7일

        // 1. DB에서 임박 아이템 조회 (Item 엔티티째로 가져오기)
        // (ItemRepository에 아래 메서드가 없으면 추가해야 함: findAllByUserIdAndExpiryDateLessThanEqual)
        List<Item> items = itemRepository.findAllByRefrigeratorUserAndExpiryDateBetweenOrderByExpiryDateAsc(
                user,
                today,      // Start
                targetDate  // End
        );

        if (items.isEmpty()) {
            return ChatbotInventoryResponseDto.builder()
                    .message("냉장고에 곧 유통기한이 마감되는 재료가 없어요.") // 멘트 살짝 수정
                    .items(List.of())
                    .build();
        }

        // 2. 화면 표시용 리스트 변환 (이름, 날짜, 용량)
        List<ItemDetailDto> detailList = items.stream().map(item -> {
            long daysLeft = ChronoUnit.DAYS.between(LocalDate.now(), item.getExpiryDate());
            String dDay = (daysLeft < 0) ? "만료" : (daysLeft == 0) ? "D-Day" : "D-" + daysLeft;

            return ItemDetailDto.builder()
                    .name(item.getName())
                    .expiryDate(item.getExpiryDate().toString())
                    .quantity(item.getQuantity())
                    .dDay(dDay)
                    .build();
        }).toList();

        // 3. 음성 출력용 문장 만들기 ("계란, 양파 있어")
        // 재료 이름만 뽑아서 쉼표로 연결
        String namesString = items.stream()
                .map(Item::getName)
                .distinct() // 중복 제거 (우유가 2개일 수 있으니까)
                .collect(Collectors.joining(", "));

        String ttsMessage = "지금 냉장고에 " + namesString + " 있어요.";

        return ChatbotInventoryResponseDto.builder()
                .message(ttsMessage)
                .items(detailList)
                .build();
    }
}