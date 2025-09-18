package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.domain.User;
import cau.team_refrigerator.refrigerator.domain.dto.PopularIngredientDto;
import cau.team_refrigerator.refrigerator.domain.dto.PopularRecipeDto;
import cau.team_refrigerator.refrigerator.repository.IngredientLogRepository;
import cau.team_refrigerator.refrigerator.repository.LikeRepository;
import cau.team_refrigerator.refrigerator.repository.RecipeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true) // 통계는 보통 조회만 하므로 readOnly = true
public class StatisticsService {

    private final IngredientLogRepository ingredientLogRepository;
    private final RecipeRepository recipeRepository;
    private final LikeRepository likeRepository;

    public List<PopularIngredientDto> getPopularIngredients(String period) {
        List<PopularIngredientDto> results;

        if ("weekly".equals(period)) {
            LocalDateTime startDate = LocalDateTime.now().minusWeeks(1);
            results = ingredientLogRepository.findPopularIngredientsSince(startDate);
        } else if ("monthly".equals(period)) {
            LocalDateTime startDate = LocalDateTime.now().minusMonths(1);
            results = ingredientLogRepository.findPopularIngredientsSince(startDate);
        } else {
            results = ingredientLogRepository.findPopularIngredients();
        }

        results.forEach(dto ->
                dto.setCoupangUrl("https://www.coupang.com/np/search?q=" + dto.getName())
        );

        return results;
    }

    public List<PopularRecipeDto> getPopularRecipes(String period, User user) {
        List<PopularRecipeDto> popularRecipes;

        if ("weekly".equals(period)) {
            // [수정] findPopularRecipesSince -> findPopularAiRecipesSince 호출
            popularRecipes = recipeRepository.findPopularAiRecipesSince(LocalDateTime.now().minusWeeks(1));
        } else if ("monthly".equals(period)) {
            // [수정] findPopularRecipesSince -> findPopularAiRecipesSince 호출
            popularRecipes = recipeRepository.findPopularAiRecipesSince(LocalDateTime.now().minusMonths(1));
        } else {
            // [수정] findPopularRecipes -> findPopularAiRecipes 호출
            popularRecipes = recipeRepository.findPopularAiRecipes();
        }

        // 'isLiked' 상태를 체크하는 로직은 수정할 필요 없습니다. (기존 코드와 동일)
        if (user != null) {
            popularRecipes.forEach(dto -> {
                boolean isLiked = likeRepository.existsByRecipeIdAndUserId(dto.getId(), user.getId());
                dto.setLiked(isLiked);
            });
        }
        return popularRecipes;
    }
}