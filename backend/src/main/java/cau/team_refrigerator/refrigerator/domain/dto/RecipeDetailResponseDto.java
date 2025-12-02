package cau.team_refrigerator.refrigerator.domain.dto;

import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.List;

@Getter
@NoArgsConstructor
public class RecipeDetailResponseDto {

    private Long favoriteId;
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

    // ❌ [삭제됨] String 타입의 중복 필드 삭제 (아래 Double 사용)
    // private String totalKcal;
    // private String estimatedPrice;

    // ✅ [유지] 계산 가능한 숫자 타입 필드들
    private Double totalKcal;          // 총 칼로리
    private Double totalCarbsG;        // 탄수화물
    private Double totalProteinG;      // 단백질
    private Double totalFatG;          // 지방
    private Double totalSodiumMg;      // 나트륨
    private Double estimatedMinPriceKrw; // 최소 가격
    private Double estimatedMaxPriceKrw; // 최대 가격 (우리는 이걸 주로 씁니다)

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