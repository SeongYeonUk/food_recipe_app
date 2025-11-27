package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.client.GptApiClient; // 👈 추가
import cau.team_refrigerator.refrigerator.domain.*;
import cau.team_refrigerator.refrigerator.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

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
}