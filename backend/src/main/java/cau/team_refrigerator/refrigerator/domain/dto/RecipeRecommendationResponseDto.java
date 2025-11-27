package cau.team_refrigerator.refrigerator.domain.dto;

import cau.team_refrigerator.refrigerator.domain.dto.RecipeBasicResponseDto.BasicRecipeItem;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RecipeRecommendationResponseDto {
    // 1. GPT가 제안한 대체 재료들 (예: ["두유", "생크림", "치즈"])
    private List<String> suggestedIngredients;

    // 2. 그 중에서 내 냉장고에 실제로 있는 것 (예: ["치즈"])
    private List<String> matchingIngredients;

    // 3. 최종 추천 레시피 목록
    private List<BasicRecipeItem> recipes;
}