// /service/SttService.java

package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.client.GptApiClient;
import cau.team_refrigerator.refrigerator.client.SttClient;
import cau.team_refrigerator.refrigerator.domain.Item;
import cau.team_refrigerator.refrigerator.domain.ItemCategory; // (경로 확인)
import cau.team_refrigerator.refrigerator.domain.Refrigerator;
import cau.team_refrigerator.refrigerator.domain.User;
import cau.team_refrigerator.refrigerator.domain.dto.GptIngredientDto;
import cau.team_refrigerator.refrigerator.repository.RefrigeratorRepository;
import cau.team_refrigerator.refrigerator.repository.UserRepository;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.exc.MismatchedInputException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Service
public class SttService {

    private final SttClient sttClient;
    private final GptApiClient gptApiClient;
    private final ItemService itemService;
    private final ObjectMapper objectMapper;
    private final UserRepository userRepository;
    private final RefrigeratorRepository refrigeratorRepository;

    private static final Logger log = LoggerFactory.getLogger(SttService.class);

    // ⭐️ 1. VALID_CATEGORIES 수정 (Enum과 일치시킴) ⭐️
    private static final Set<String> VALID_CATEGORIES = Collections.unmodifiableSet(
            new HashSet<>(Arrays.asList("채소", "과일", "육류", "어패류", "유제품", "가공식품", "음료", "곡물", "기타"))
    );

    // 5. 생성자
    public SttService(SttClient sttClient, GptApiClient gptApiClient,
                      ItemService itemService, ObjectMapper objectMapper,
                      UserRepository userRepository, RefrigeratorRepository refrigeratorRepository) {
        this.sttClient = sttClient;
        this.gptApiClient = gptApiClient;
        this.itemService = itemService;
        this.objectMapper = objectMapper;
        this.userRepository = userRepository;
        this.refrigeratorRepository = refrigeratorRepository;
    }

    @Transactional
    public void processAudio(byte[] audioBytes) throws IOException { // 1. (수정) MultipartFile -> byte[]

        // --- 0. 현재 사용자 정보 및 냉장고 조회 ---
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String currentUserId = authentication.getName();

        User currentUser = userRepository.findByUid(currentUserId) // TODO 1: findByUid가 맞는지 확인
                .orElseThrow(() -> new RuntimeException("현재 사용자를 찾을 수 없습니다: " + currentUserId));

        // TODO 2: 사용자의 "기본" 냉장고를 찾는 로직 확인
        Refrigerator currentRefrigerator = refrigeratorRepository.findByUser(currentUser).stream().findFirst()
                .orElseThrow(() -> new RuntimeException("사용자의 냉장고를 찾을 수 없습니다."));


        // 1. STT API 호출
        // 2. (삭제) byte[] audioBytes = audioFile.getBytes();
        String sttText = sttClient.callGoogleSttApi(audioBytes); // (정상 작동)
        log.info("STT 결과: {}", sttText);

        if (sttText == null || sttText.contains("인식된 텍스트 없음")) {
            log.warn("인식된 텍스트가 없어 GPT 호출을 중단합니다.");
            return;
        }

        // 2. GPT API로 전송
        log.info("GPT API 호출 중...");
        String gptJsonResult = gptApiClient.callGptApi(sttText);
        log.info("GPT 분석 결과 (JSON): {}", gptJsonResult);



        // --- 3. [수정됨] JSON 파싱 및 DB 저장 (오류 처리 강화) ---
        try {
            List<GptIngredientDto> dtos = null; // 1. dtos를 null로 초기화

            try {
                // --- 시도 1: GPT가 JSON 배열 [...]을 바로 반환한 경우 ---
                dtos = objectMapper.readValue(
                        gptJsonResult,
                        new TypeReference<List<GptIngredientDto>>() {}
                );
                log.info("GPT JSON 파싱 성공 (Case 1: Raw Array)");

            } catch (MismatchedInputException e) {
                // --- 시도 2: GPT가 JSON 객체 {"ingredients": [...]}를 반환한 경우 ---
                log.warn("GPT가 배열이 아닌 객체를 반환. (Case 2: Object) 파싱 재시도...");
                try {
                    JsonNode rootNode = objectMapper.readTree(gptJsonResult);
                    JsonNode ingredientsNode = rootNode.path("ingredients");

                    // ingredientsNode가 존재하면 List로 변환, 없으면 null이 됨
                    dtos = objectMapper.convertValue(
                            ingredientsNode,
                            new TypeReference<List<GptIngredientDto>>() {}
                    );
                    log.info("GPT JSON 파싱 성공 (Case 2: Object)");

                } catch (Exception e2) {
                    // 두 번째 시도(객체 파싱)도 실패하면, 진짜 오류
                    log.error("GPT JSON 파싱 중 심각한 오류 발생 (Case 2 실패)", e2);
                    return; // 중단
                }
            }

            // --- 🛡️ NullPointerException 방지 ---
            // (Case 2에서 "ingredients" 키가 없었거나, 파싱 결과가 null인 경우)
            if (dtos == null) {
                log.warn("GPT가 유효한 아이템 리스트를 반환하지 않았습니다 (dtos is null).");
                return;
            }
            // --- 🛡️ ---

            List<Item> itemsToSave = new ArrayList<>();

            // 4. 이제 dtos는 null이 아니므로 이 코드는 안전합니다. (이전 110번 줄)
            for (GptIngredientDto dto : dtos) {

                // 🛡️ 안전장치 1: 이름 검증
                if (dto.getName() == null || dto.getName().isBlank()) {
                    log.warn("GPT DTO에 이름이 없어 스킵합니다.");
                    continue;
                }

                // 🛡️ 안전장치 2: 카테고리 문자열 검증
                String gptCategory = dto.getCategory();
                if (gptCategory == null || !VALID_CATEGORIES.contains(gptCategory)) {
                    log.warn("잘못된 카테고리 '{}' 감지. '기타'로 변경.", gptCategory);
                    gptCategory = "기타"; // '안전장치' 발동
                }

                // 🛡️ 안전장치 3: 날짜 형식(YYYY-MM-DD) 검증
                LocalDate expiryDate = parseDateSafely(dto.getExpirationDate());

                // --- 4. Item 엔티티 빌드 (도메인 모델에 맞게 수정) ---
                Item newItem = Item.builder()
                        .name(dto.getName())
                        .quantity(dto.getQuantity())
                        .registrationDate(LocalDate.now())
                        .expiryDate(expiryDate)
                        .category(convertCategory(gptCategory))
                        .refrigerator(currentRefrigerator)
                        .iconIndex(0) // TODO: 아이콘 인덱스 로직 필요시 추가
                        .build();

                itemsToSave.add(newItem);
            }

            // 5. ItemService를 통해 DB에 일괄 저장
            if (!itemsToSave.isEmpty()) {
                itemService.saveAllItems(itemsToSave);
                log.info("{}개의 아이템이 성공적으로 저장되었습니다.", itemsToSave.size());
            } else {
                log.warn("GPT가 유효한 아이템을 반환하지 않았습니다.");
            }

        } catch (Exception e) {
            log.error("GPT JSON 파싱 또는 DB 저장 중 심각한 오류 발생", e);
        }
    }

    /**
     * 🛡️ [안전장치] 날짜 파싱 헬퍼 메소드
     */
    private LocalDate parseDateSafely(String dateString) {
        if (dateString == null) {
            return null;
        }
        try {
            return LocalDate.parse(dateString);
        } catch (DateTimeParseException e) {
            log.warn("잘못된 날짜 형식 '{}' 감지. null로 처리.", dateString);
            return null;
        }
    }

    /**
     * 🛡️ ⭐️ [안전장치] GPT 카테고리(String)를 ItemCategory(Enum)로 변환 ⭐️
     * (님의 Enum에 맞게 수정됨)
     */
    private ItemCategory convertCategory(String gptCategory) {
        switch (gptCategory) {
            case "채소":
                return ItemCategory.채소;
            case "과일":
                return ItemCategory.과일;
            case "육류":
                return ItemCategory.육류;
            case "어패류":
                return ItemCategory.어패류;
            case "유제품":
                return ItemCategory.유제품; // (ItemType이 아니라 ItemCategory가 맞을 것 같습니다. 확인 필요)
            case "가공식품":
                return ItemCategory.가공식품;
            case "음료":
                return ItemCategory.음료;
            case "곡물":
                return ItemCategory.곡물;
            case "기타":
            default:
                return ItemCategory.기타;
        }
    }
}
