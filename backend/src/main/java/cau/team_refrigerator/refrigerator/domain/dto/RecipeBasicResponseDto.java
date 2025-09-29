package cau.team_refrigerator.refrigerator.domain.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;
import lombok.NoArgsConstructor;
import java.util.List;

// AllArgsConstructor는 DTO 클래스 자체에는 필요 없으므로 제거해도 괜찮습니다.
@Getter
@NoArgsConstructor
public class RecipeBasicResponseDto {

    @JsonProperty("Grid_20150827000000000226_1")
    private NongsangData nongsangData;

    @Getter
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class NongsangData {
        @JsonProperty("totalCnt")
        private int total_count;

        private List<BasicRecipeItem> row;
    }

    @Getter
    @NoArgsConstructor
    public static class BasicRecipeItem {
        @JsonProperty("RECIPE_ID")
        private String recipeId;

        @JsonProperty("RECIPE_NM_KO")
        private String recipeNameKo;

        @JsonProperty("SUMRY")
        private String summary;

        @JsonProperty("NATION_CODE")
        private String nationCode;

        @JsonProperty("NATION_NM")
        private String nationName;

        @JsonProperty("TY_CODE")
        private String typeCode;

        @JsonProperty("TY_NM")
        private String typeName;

        @JsonProperty("COOKING_TIME")
        private String cookingTime;

        @JsonProperty("CALORIE")
        private String calorie;

        @JsonProperty("QNT")
        private String quantity;

        @JsonProperty("LEVEL_NM")
        private String levelName;

        @JsonProperty("IRDNT_CODE")
        private String ingredientCode;

        @JsonProperty("PC_NM")
        private String priceName;

        @JsonProperty("IMG_URL") // 👈 이 필드와 어노테이션을 추가했습니다.
        private String imageUrl;
    }
}