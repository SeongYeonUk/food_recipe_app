package cau.team_refrigerator.refrigerator.domain.dto;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;
import lombok.NoArgsConstructor;
import java.util.List;

@Getter
@NoArgsConstructor
public class RecipeCourseResponseDto {

    @JsonProperty("Grid_20150827000000000228_1")
    private NongsangData nongsangData;

    @Getter
    @NoArgsConstructor
    public static class NongsangData {
        private int total_count;
        private List<CourseItem> row;
    }

    @Getter
    @NoArgsConstructor
    public static class CourseItem {
        @JsonProperty("RECIPE_ID")
        private String recipeId;

        @JsonProperty("COOKING_NO")
        private String cookingNumber; // 요리 설명 순서

        @JsonProperty("COOKING_DC")
        private String cookingDescription; // 요리 설명

        @JsonProperty("STEP_TIP")
        private String stepTip; // 과정 팁
    }
}