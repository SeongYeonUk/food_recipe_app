package cau.team_refrigerator.refrigerator.domain.dto;

import lombok.Builder;
import lombok.Getter;
import java.util.List;

@Getter
@Builder
public class RecipeDetailResponseDto
{

    private final Long recipeId; // id (프론트에서 String 변환)
    private final String recipeName; // name

    private final List<String> ingredients;
    private final List<String> instructions;

    private final int likeCount; // likes
    private final String cookingTime; // cookingTime (예: "30분")
    private final String imageUrl; // imageAssetPath 대체

    private final boolean isCustom;
    private final String userReaction; // "none", "liked" 등

    private final UserDto user;

    @Getter
    @Builder
    public static class UserDto {
        private final Long userId;
        private final String nickname;
    }
}