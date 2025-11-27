package cau.team_refrigerator.refrigerator.domain.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@NoArgsConstructor
public class RecipeRecommendationRequestDto {
    private boolean useExpiringIngredients; // 유통기한 임박 재료 사용 여부
    private String tastePreference;         // 맛 취향 (예: "매콤한")
    private List<String> mustUseIngredients; // 꼭 써야 하는 재료
    private Integer timeLimitMinutes;       // 시간 제한 (분)

    // 대체 재료 관련
    private String missingIngredient;       // 사용자가 없다고 한 재료
    private List<String> substituteIngredients; // GPT가 제안한 대체 재료 후보들
}