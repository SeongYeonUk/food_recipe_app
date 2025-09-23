package cau.team_refrigerator.refrigerator.domain.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;
import lombok.NoArgsConstructor;
import java.util.List;

@Getter
@NoArgsConstructor
public class RecipeBasicResponseDto {

    @JsonProperty("Grid_20150827000000000226_1")
    private NongsangData nongsangData;

    @Getter
    @NoArgsConstructor
    public static class NongsangData {
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
    }
}