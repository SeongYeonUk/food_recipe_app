package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.client.GptApiClient;
import cau.team_refrigerator.refrigerator.domain.Recipe;
import cau.team_refrigerator.refrigerator.domain.RecipeIngredient;
import cau.team_refrigerator.refrigerator.repository.RecipeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class RecipeNormalizationService {

    private final RecipeRepository recipeRepository;
    private final GptApiClient gptApiClient;

    @Transactional
    public void normalizeAllRecipes() {
        // 모든 AI 레시피 조회
        List<Recipe> targetRecipes = recipeRepository.findByIsCustomFalse();
        System.out.println("총 " + targetRecipes.size() + "개의 레시피를 1인분으로 변환 시작...");

        int successCount = 0;

        for (Recipe recipe : targetRecipes) {
            try {
                normalizeSingleRecipe(recipe);
                successCount++;
                // GPT API 제한(Rate Limit) 방지를 위해 1초 정도 쉬어주는 게 좋습니다.
                Thread.sleep(1000);
            } catch (Exception e) {
                System.err.println("레시피 변환 실패 (ID: " + recipe.getId() + "): " + e.getMessage());
            }
        }
        System.out.println("변환 완료! 성공: " + successCount);
    }
    @Transactional // 👈 이게 있어야 DB에 저장이 됩니다! (매우 중요)
    public void normalizeSpecificRecipe(Long recipeId) {
        Recipe recipe = recipeRepository.findById(recipeId)
                .orElseThrow(() -> new IllegalArgumentException("레시피 없음"));

        System.out.println(">>> 타겟 레시피: " + recipe.getTitle() + " (ID: " + recipeId + ") 변환 시작");
        normalizeSingleRecipe(recipe);
        System.out.println(">>> 변환 종료.");
    }

    private void normalizeSingleRecipe(Recipe recipe) {
        List<RecipeIngredient> ingredients = recipe.getRecipeIngredients();
        if (ingredients.isEmpty()) return;

        Map<String, String> currentMap = new HashMap<>();
        for (RecipeIngredient ri : ingredients) {
            currentMap.put(ri.getIngredient().getName(), ri.getAmount());
        }

        // GPT에게 1인분 변환 요청
        Map<String, String> normalizedMap = gptApiClient.normalizeIngredients(recipe.getTitle(), currentMap);

        if (normalizedMap == null || normalizedMap.isEmpty()) return;

        for (RecipeIngredient ri : ingredients) {
            String name = ri.getIngredient().getName();
            if (normalizedMap.containsKey(name)) {
                String newAmount = normalizedMap.get(name);
                if (!ri.getAmount().equals(newAmount)) {
                    System.out.printf("[%s] %s: %s -> %s\n", recipe.getTitle(), name, ri.getAmount(), newAmount);
                    ri.setAmount(newAmount); // 값 변경 (JPA Dirty Checking으로 자동 저장됨)
                }
            }
        }
    }
}