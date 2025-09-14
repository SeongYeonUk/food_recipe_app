package cau.team_refrigerator.refrigerator.domain.dto;

import lombok.Getter;
import java.util.List;

@Getter
public class RecipeCreateRequestDto {

    private String title;
    private String description;
    private List<IngredientDto> ingredients;
    private List<String> instructions;
    private int time;
    private String imageUrl;
    private boolean isCustom; // AI 레시피와 구분하기 위한 필드

    // 재료 입력을 위한 중첩 DTO
    @Getter
    public static class IngredientDto {
        private String name;
        private String amount;
    }
}