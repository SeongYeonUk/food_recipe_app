package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.client.ApiClient;
import cau.team_refrigerator.refrigerator.domain.Ingredient;
import cau.team_refrigerator.refrigerator.domain.Recipe;
import cau.team_refrigerator.refrigerator.domain.RecipeIngredient;
import cau.team_refrigerator.refrigerator.domain.dto.RecipeBasicResponseDto.BasicRecipeItem;
import cau.team_refrigerator.refrigerator.repository.IngredientRepository;
import cau.team_refrigerator.refrigerator.repository.RecipeRepository;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class RecipeBatchService {

    private final ApiClient apiClient;
    private final RecipeRepository recipeRepository;
    private final IngredientRepository ingredientRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * 매일 새벽 4시에 이 메소드를 자동으로 실행합니다.
     * (cron = "초 분 시 일 월 요일")
     * (테스트 시에는 @Scheduled 어노테이션을 잠시 주석 처리하고, Postman 등으로 호출할 API를 만드세요)
     */
    @Scheduled(cron = "45 40 6 * * *")
    @Transactional
    public void syncRecipesFromApi() {
        System.out.println("===== [배치 작업 시작] 공공 API 레시피 동기화를 시작합니다. =====");

        int startIndex = 1;
        final int pageSize = 100; // API가 한 번에 100개씩 지원
        int totalSavedCount = 0;
        boolean hasMoreData = true;
        final int MAX_RECIPES_TO_FETCH = 200; // 👈 최대 200개 제한 설정

        // 👇 루프 조건에 startIndex <= MAX_RECIPES_TO_FETCH 추가 👇
        while (hasMoreData && startIndex <= MAX_RECIPES_TO_FETCH) {
            int endIndex = startIndex + pageSize - 1;

            // 1. ApiClient의 배치 전용 메소드 호출
            String jsonString = apiClient.getAllRecipesForBatch(startIndex, endIndex);

            if (jsonString == null) {
                System.err.println("API 호출 실패. 배치를 중단합니다.");
                break;
            }

            try {
                // 2. JSON 파싱
                JsonNode rootNode = objectMapper.readTree(jsonString);
                JsonNode gridNode = rootNode.fields().next().getValue();
                JsonNode rowNode = gridNode.get("row");
                int totalApiCount = gridNode.get("totalCnt").asInt(); // API 전체 개수 (참고용)

                if (rowNode != null && rowNode.isArray() && rowNode.size() > 0) {
                    List<BasicRecipeItem> items = objectMapper.convertValue(
                            rowNode, new TypeReference<List<BasicRecipeItem>>() {}
                    );

                    // 3. DB에 저장 (최대 200개까지만 저장되도록 내부 로직 추가 가능)
                    // 현재 saveItemsToDb는 중복 체크만 하므로, 여기서 추가 제한은 불필요
                    int savedCountInThisPage = saveItemsToDb(items);
                    totalSavedCount += savedCountInThisPage;

                    // 4. 다음 페이지 준비
                    startIndex += pageSize;

                    // API 자체 데이터보다 적게 가져오는 것이므로, totalApiCount 비교는 불필요
                    // if (startIndex > totalApiCount) { hasMoreData = false; }

                    // 200개를 넘어가면 루프 중단
                    if (startIndex > MAX_RECIPES_TO_FETCH) {
                        hasMoreData = false;
                    }

                } else {
                    hasMoreData = false; // 데이터 없음
                }

            } catch (IOException e) {
                e.printStackTrace();
                System.err.println("JSON 파싱 중 오류 발생. 배치를 중단합니다.");
                hasMoreData = false; // 파싱 오류 시 중단
            }
        }
        System.out.println("===== [배치 작업 종료] 총 " + totalSavedCount + "개의 신규 레시피를 DB에 저장했습니다. =====");
    }

    /**
     * DTO 리스트를 받아서 Recipe 엔티티로 변환 후 DB에 저장
     */

    // ... (RecipeBatchService 클래스 내부)

    /**
     * DTO 리스트를 받아서 Recipe 엔티티로 변환 후 DB에 저장
     * (재료와 과정 정보 가져오는 로직 추가)
     */
    private int saveItemsToDb(List<BasicRecipeItem> items) {
        int newRecipeCount = 0;
        for (BasicRecipeItem item : items) {

            String apiRecipeId = item.getRecipeId();

            // 1. 중복 체크 (기존과 동일)
            if (!recipeRepository.existsByApiRecipeId(apiRecipeId)) {

                // 👇👇👇 2. 재료 및 과정 정보 가져오기 (API 추가 호출) 👇👇👇
                String ingredientsJson = apiClient.searchIngredients(apiRecipeId);
                String courseJson = apiClient.searchRecipeCourse(apiRecipeId);

                // 3. 파싱해서 문자열로 만들기 (간단 버전)
                String ingredientsText = parseIngredients(ingredientsJson); // 예: "쌀 4컵, 안심 200g, ..."
                String instructionsText = parseCourse(courseJson);      // 예: "1. 양지머리로 육수를... \n 2. 안심은 불고기 양념..."

                // 4. DTO -> Entity 변환 (재료/과정 정보 포함)
                Recipe newRecipe = Recipe.builder()
                        .apiRecipeId(apiRecipeId)
                        .title(item.getRecipeNameKo())
                        .description(item.getSummary())
                        .time(parseCookingTime(item.getCookingTime()))
                        .imageUrl(item.getImageUrl())
                        .isCustom(false)
                        .instructions(instructionsText) // 👈 저장
                        .recipeIngredients(new ArrayList<>())
                        .build();

                parseAndAddIngredients(newRecipe, ingredientsJson); // 👈 헬퍼 메소드 호출

                // 5. DB에 저장 (기존과 동일)
                recipeRepository.save(newRecipe);
                newRecipeCount++;
            }
        }
        return newRecipeCount;
    }
    /**
     * [신규] 재료 JSON을 파싱하여 Ingredient 찾기/생성 후 RecipeIngredient 를 Recipe에 추가
     */
    private void parseAndAddIngredients(Recipe recipe, String jsonString) {
        if (jsonString == null) return;
        try {
            JsonNode rootNode = objectMapper.readTree(jsonString);
            JsonNode gridNode = rootNode.fields().next().getValue();
            JsonNode rowNode = gridNode.get("row");
            if (rowNode != null && rowNode.isArray()) {
                for (JsonNode ingredientNode : rowNode) {
                    String name = ingredientNode.path("IRDNT_NM").asText(null); // 재료명
                    String amount = ingredientNode.path("IRDNT_CPCTY").asText(null); // 용량

                    if (name != null && !name.trim().isEmpty()) {
                        // 1. Ingredient 찾기 또는 생성
                        Ingredient ingredient = findOrCreateIngredient(name.trim());

                        // 2. RecipeIngredient 생성
                        RecipeIngredient recipeIngredient = RecipeIngredient.builder()
                                .recipe(recipe) // 연관관계 설정
                                .ingredient(ingredient) // 연관관계 설정
                                .amount(amount)
                                .build();

                        // 3. Recipe 엔티티에 추가 (양방향 연관관계 설정 포함)
                        recipe.addRecipeIngredient(recipeIngredient);
                    } else {
                        System.out.println("  -> 이름이 비어있어 건너뜀. ");
                    }
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
            System.err.println("재료 정보 파싱 중 오류 발생 (Recipe ID: " + recipe.getApiRecipeId() + ")");
        }
    }

    /**
     * [신규] IngredientRepository를 사용하여 Ingredient 찾기 또는 생성
     */
    private Ingredient findOrCreateIngredient(String name) {
        return ingredientRepository.findByName(name)
                .orElseGet(() -> {
                    System.out.println("새로운 재료 발견 및 저장: " + name);
                    return ingredientRepository.save(Ingredient.builder().name(name).build());
                });
    }

    // --- Helper methods for parsing ---

    /**
     * 재료 정보 JSON을 파싱해서 한 줄의 문자열로 합칩니다.
     * (예: "쌀 4컵, 안심 200g, 콩나물 20g")
     */
    private String parseIngredients(String jsonString) {
        if (jsonString == null) return null;
        try {
            JsonNode rootNode = objectMapper.readTree(jsonString);
            JsonNode gridNode = rootNode.fields().next().getValue();
            JsonNode rowNode = gridNode.get("row");
            if (rowNode != null && rowNode.isArray()) {
                StringBuilder sb = new StringBuilder();
                for (JsonNode ingredientNode : rowNode) {
                    String name = ingredientNode.path("IRDNT_NM").asText(""); // 재료명
                    String capacity = ingredientNode.path("IRDNT_CPCTY").asText(""); // 용량
                    if (!name.isEmpty()) {
                        if (sb.length() > 0) sb.append(", ");
                        sb.append(name);
                        if (!capacity.isEmpty()) sb.append(" ").append(capacity);
                    }
                }
                return sb.toString();
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        return null;
    }

    /**
     * 과정 정보 JSON을 파싱해서 여러 줄의 문자열로 합칩니다.
     * (예: "1. 양지머리로 육수를...\n2. 안심은 불고기 양념...")
     */
    private String parseCourse(String jsonString) {
        if (jsonString == null) return null;
        try {
            JsonNode rootNode = objectMapper.readTree(jsonString);
            JsonNode gridNode = rootNode.fields().next().getValue();
            JsonNode rowNode = gridNode.get("row");
            if (rowNode != null && rowNode.isArray()) {
                StringBuilder sb = new StringBuilder();
                for (JsonNode stepNode : rowNode) {
                    String stepNumber = stepNode.path("COOKING_NO").asText(""); // 순서
                    String description = stepNode.path("COOKING_DC").asText(""); // 설명
                    if (!description.isEmpty()) {
                        if (sb.length() > 0) sb.append("\n"); // 줄바꿈
                        if (!stepNumber.isEmpty()) sb.append(stepNumber).append(". ");
                        sb.append(description);
                    }
                }
                return sb.toString();
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        return null;
    }

    /**
     * "60분" 같은 문자열을 Integer 60으로 변환하는 헬퍼 메소드
     */
    private Integer parseCookingTime(String cookingTime) {
        if (cookingTime == null || cookingTime.isEmpty()) {
            return null;
        }
        try {
            // "분"이나 "시간" 등 모든 문자열을 제거하고 숫자만 남김
            String digits = cookingTime.replaceAll("[^0-9]", "");
            return Integer.parseInt(digits);
        } catch (NumberFormatException e) {
            return null; // 숫자로 변환 실패 시 null 반환
        }
    }
}