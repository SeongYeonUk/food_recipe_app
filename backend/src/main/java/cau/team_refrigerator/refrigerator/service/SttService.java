package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.client.GptApiClient;
import cau.team_refrigerator.refrigerator.client.SttClient;
import cau.team_refrigerator.refrigerator.domain.Item;
import cau.team_refrigerator.refrigerator.domain.ItemCategory;
import cau.team_refrigerator.refrigerator.domain.Refrigerator;
import cau.team_refrigerator.refrigerator.domain.User;
import cau.team_refrigerator.refrigerator.domain.dto.GptIngredientDto;
import cau.team_refrigerator.refrigerator.repository.RefrigeratorRepository;
import cau.team_refrigerator.refrigerator.repository.UserRepository;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.exc.MismatchedInputException;
import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class SttService {

    private final SttClient sttClient;
    private final GptApiClient gptApiClient;
    private final ItemService itemService;
    private final ObjectMapper objectMapper;
    private final UserRepository userRepository;
    private final RefrigeratorRepository refrigeratorRepository;

    private static final Logger log = LoggerFactory.getLogger(SttService.class);

    private static final Set<String> VALID_CATEGORIES = Collections.unmodifiableSet(
            new HashSet<>(List.of("채소", "과일", "유제품", "육류", "음료", "가공식품", "조미료", "곡물", "기타"))
    );

    public SttService(
            SttClient sttClient,
            GptApiClient gptApiClient,
            ItemService itemService,
            ObjectMapper objectMapper,
            UserRepository userRepository,
            RefrigeratorRepository refrigeratorRepository
    ) {
        this.sttClient = sttClient;
        this.gptApiClient = gptApiClient;
        this.itemService = itemService;
        this.objectMapper = objectMapper;
        this.userRepository = userRepository;
        this.refrigeratorRepository = refrigeratorRepository;
    }

    /**
     * 음성(STT) 결과를 GPT로 분석하여 식재료 리스트만 반환합니다.
     * DB에는 저장하지 않고, 사용자가 선택한 뒤 saveSelectedIngredients로 저장합니다.
     */
    public List<GptIngredientDto> processAudio(byte[] audioBytes) throws IOException {
        String sttText = sttClient.callGoogleSttApi(audioBytes);
        log.info("STT 결과: {}", sttText);

        if (sttText == null || sttText.contains("인식된 텍스트 없음")) {
            log.warn("인식된 텍스트가 없어 GPT 호출을 중단합니다.");
            return Collections.emptyList();
        }

        String gptJsonResult = gptApiClient.callGptApi(sttText);
        log.info("GPT 분석 결과 (JSON): {}", gptJsonResult);

        List<GptIngredientDto> parsed = parseGptResult(gptJsonResult);
        if (parsed.isEmpty()) {
            log.warn("GPT가 유효한 재료 목록을 반환하지 않았습니다.");
        }

        // 이름이 비어 있는 항목은 제외하여 반환
        List<GptIngredientDto> cleaned = new ArrayList<>();
        for (GptIngredientDto dto : parsed) {
            if (dto.getName() != null && !dto.getName().isBlank()) {
                cleaned.add(dto);
            }
        }
        return cleaned;
    }

    /**
     * 사용자가 선택한 재료들을 실제 DB에 저장합니다.
     * @return 저장된 건수
     */
    @Transactional
    public int saveSelectedIngredients(List<GptIngredientDto> dtos) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String currentUserId = authentication.getName();

        User currentUser = userRepository.findByUid(currentUserId)
                .orElseThrow(() -> new RuntimeException("현재 사용자를 찾을 수 없습니다: " + currentUserId));

        Refrigerator currentRefrigerator = refrigeratorRepository.findByUser(currentUser).stream().findFirst()
                .orElseThrow(() -> new RuntimeException("사용자의 냉장고를 찾을 수 없습니다."));

        List<Item> itemsToSave = new ArrayList<>();

        for (GptIngredientDto dto : dtos) {
            if (dto.getName() == null || dto.getName().isBlank()) {
                log.warn("DTO에 이름이 없어 건너뜁니다.");
                continue;
            }

            String gptCategory = dto.getCategory();
            if (gptCategory == null || !VALID_CATEGORIES.contains(gptCategory)) {
                log.warn("알 수 없는 카테고리 '{}' 감지. '기타'로 변환.", gptCategory);
                gptCategory = "기타";
            }

            LocalDate expiryDate = parseDateSafely(dto.getExpirationDate());

            Item newItem = Item.builder()
                    .name(dto.getName())
                    .quantity(dto.getQuantity())
                    .registrationDate(LocalDate.now())
                    .expiryDate(expiryDate)
                    .category(convertCategory(gptCategory))
                    .refrigerator(currentRefrigerator)
                    .iconIndex(0)
                    .build();

            itemsToSave.add(newItem);
        }

        if (itemsToSave.isEmpty()) {
            log.warn("저장할 유효한 재료가 없습니다.");
            return 0;
        }

        itemService.saveAllItems(itemsToSave);
        log.info("{}개의 재료가 저장되었습니다.", itemsToSave.size());
        return itemsToSave.size();
    }

    private List<GptIngredientDto> parseGptResult(String gptJsonResult) {
        try {
            return objectMapper.readValue(
                    gptJsonResult,
                    new TypeReference<List<GptIngredientDto>>() {}
            );
        } catch (MismatchedInputException e) {
            log.warn("GPT가 배열이 아닌 객체 형태를 반환. ingredients 필드로 파싱 시도.");
            try {
                JsonNode rootNode = objectMapper.readTree(gptJsonResult);
                JsonNode ingredientsNode = rootNode.path("ingredients");
                if (ingredientsNode.isMissingNode() || ingredientsNode.isNull()) {
                    return Collections.emptyList();
                }
                return objectMapper.convertValue(
                        ingredientsNode,
                        new TypeReference<List<GptIngredientDto>>() {}
                );
            } catch (Exception inner) {
                log.error("GPT JSON 파싱 중 예외 발생", inner);
                return Collections.emptyList();
            }
        } catch (Exception e) {
            log.error("GPT JSON 파싱 중 알 수 없는 예외 발생", e);
            return Collections.emptyList();
        }
    }

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

    private ItemCategory convertCategory(String gptCategory) {
        switch (gptCategory) {
            case "채소":
                return ItemCategory.채소;
            case "과일":
                return ItemCategory.과일;
            case "유제품":
                return ItemCategory.유제품;
            case "육류":
                return ItemCategory.육류;
            case "음료":
                return ItemCategory.음료;
            case "가공식품":
                return ItemCategory.가공식품;
            case "조미료":
                return ItemCategory.조미료;
            case "곡물":
                return ItemCategory.곡물;
            case "기타":
            default:
                return ItemCategory.기타;
        }
    }
}
