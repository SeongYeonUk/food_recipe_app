package cau.team_refrigerator.refrigerator.domain.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;
import lombok.NoArgsConstructor;
import java.util.List;

@Getter
@NoArgsConstructor
public class RecipeIngredientResponseDto {

    // API 응답의 최상위 객체 이름에 따라 변경
    @JsonProperty("Grid_20150827000000000227_1")
    private NongsangData nongsangData;

    @Getter
    @NoArgsConstructor
    public static class NongsangData {
        private int total_count;
        private List<IngredientItem> row;
    }

    @Getter
    @NoArgsConstructor
    public static class IngredientItem {
        @JsonProperty("RECIPE_ID")
        private String recipeId;

        @JsonProperty("IRDNT_SN")
        private String ingredientSequenceNumber; // 재료순번

        @JsonProperty("IRDNT_NM")
        private String ingredientName; // 재료명

        @JsonProperty("IRDNT_CPCTY")
        private String ingredientAmount; // 재료용량

        @JsonProperty("IRDNT_TY_CODE")
        private String ingredientTypeCode; // 재료타입 코드

        @JsonProperty("IRDNT_TY_NM")
        private String ingredientTypeName; // 재료타입명
    }
}