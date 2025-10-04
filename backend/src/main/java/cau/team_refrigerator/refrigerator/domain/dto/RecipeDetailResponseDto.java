package cau.team_refrigerator.refrigerator.domain.dto;

import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.List;

@Getter
@NoArgsConstructor // Builder를 사용하려면 기본 생성자가 필요할 수 있습니다.
public class RecipeDetailResponseDto {

    private Long favoriteId;   // [추가] '나만의 레시피'의 고유 ID
    private Long recipeId;
    private String recipeName;
    private List<String> ingredients;
    private List<String> instructions;
    private int likeCount;
    private String cookingTime;
    private String imageUrl;
    private boolean isCustom;
    private boolean isFavorite; // [추가] 현재 사용자가 즐겨찾기 했는지 여부
    private String userReaction;
    private UserDto user;

    @Builder
    public RecipeDetailResponseDto(Long favoriteId, Long recipeId, String recipeName, List<String> ingredients, List<String> instructions, int likeCount, String cookingTime, String imageUrl, boolean isCustom, boolean isFavorite, String userReaction, UserDto user) {
        this.favoriteId = favoriteId;
        this.recipeId = recipeId;
        this.recipeName = recipeName;
        this.ingredients = ingredients;
        this.instructions = instructions;
        this.likeCount = likeCount;
        this.cookingTime = cookingTime;
        this.imageUrl = imageUrl;
        this.isCustom = isCustom;
        this.isFavorite = isFavorite;
        this.userReaction = userReaction;
        this.user = user;
    }

    @Getter
    @NoArgsConstructor
    public static class UserDto {
        private Long userId;
        private String nickname;

        @Builder
        public UserDto(Long userId, String nickname) {
            this.userId = userId;
            this.nickname = nickname;
        }
    }
}