package cau.team_refrigerator.refrigerator.domain.dto;

import cau.team_refrigerator.refrigerator.domain.Recipe;
import lombok.Getter;

@Getter
public class MyRecipeResponseDto {
    private final Long recipeId;
    private final String title;
    private final String imageUrl;
    private final Integer time;

    // Recipe Entity를 받아서 DTO로 변환해주는 생성자
    public MyRecipeResponseDto(Recipe recipe) {
        this.recipeId = recipe.getId();
        this.title = recipe.getTitle();
        this.imageUrl = recipe.getImageUrl();
        this.time = recipe.getTime();
    }
}
