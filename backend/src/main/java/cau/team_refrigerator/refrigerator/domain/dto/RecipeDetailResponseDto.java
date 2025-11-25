package cau.team_refrigerator.refrigerator.domain.dto;

import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.List;

@Getter
@NoArgsConstructor
public class RecipeDetailResponseDto {

    private Long favoriteId;   // 즐겨찾기 row id (없으면 null)
    private Long recipeId;
    private String recipeName;
    private List<String> ingredients;
    private List<String> instructions;
    private int likeCount;
    private String cookingTime;
    private String imageUrl;
    private boolean isCustom;
    private boolean isFavorite;
    private String userReaction;
    private UserDto user;

    // Nutrition / price totals (nullable when not calculated)
    private Double totalKcal;
    private Double totalCarbsG;
    private Double totalProteinG;
    private Double totalFatG;
    private Double totalSodiumMg;
    private Double estimatedMinPriceKrw;
    private Double estimatedMaxPriceKrw;

    @Builder
    public RecipeDetailResponseDto(Long favoriteId,
                                   Long recipeId,
                                   String recipeName,
                                   List<String> ingredients,
                                   List<String> instructions,
                                   int likeCount,
                                   String cookingTime,
                                   String imageUrl,
                                   boolean isCustom,
                                   boolean isFavorite,
                                   String userReaction,
                                   UserDto user,
                                   Double totalKcal,
                                   Double totalCarbsG,
                                   Double totalProteinG,
                                   Double totalFatG,
                                   Double totalSodiumMg,
                                   Double estimatedMinPriceKrw,
                                   Double estimatedMaxPriceKrw) {
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
        this.totalKcal = totalKcal;
        this.totalCarbsG = totalCarbsG;
        this.totalProteinG = totalProteinG;
        this.totalFatG = totalFatG;
        this.totalSodiumMg = totalSodiumMg;
        this.estimatedMinPriceKrw = estimatedMinPriceKrw;
        this.estimatedMaxPriceKrw = estimatedMaxPriceKrw;
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
