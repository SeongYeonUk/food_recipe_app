package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.domain.Item;
import cau.team_refrigerator.refrigerator.domain.User;
import cau.team_refrigerator.refrigerator.domain.dto.IngredientCountDto;
import cau.team_refrigerator.refrigerator.domain.dto.PopularIngredientDto;
import cau.team_refrigerator.refrigerator.domain.dto.PopularRecipeDto;
import cau.team_refrigerator.refrigerator.repository.IngredientLogRepository;
import cau.team_refrigerator.refrigerator.repository.ItemRepository;
import cau.team_refrigerator.refrigerator.repository.LikeRepository;
import cau.team_refrigerator.refrigerator.repository.RecipeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true) // 통계는 보통 조회만 하므로 readOnly = true
public class StatisticsService {

    private final IngredientLogRepository ingredientLogRepository;
    private final RecipeRepository recipeRepository;
    private final LikeRepository likeRepository;
    private final ItemRepository itemRepository;

    public List<PopularIngredientDto> getPopularIngredients(String period) {
        LocalDateTime startDate;
        if ("weekly".equalsIgnoreCase(period)) {
            startDate = LocalDateTime.now().minusWeeks(1);
        } else if ("monthly".equalsIgnoreCase(period)) {
            startDate = LocalDateTime.now().minusMonths(1);
        } else {
            startDate = LocalDateTime.of(2000, 1, 1, 0, 0);
        }

        Pageable topTen = PageRequest.of(0, 10);
        List<Object[]> results = ingredientLogRepository.findPopularIngredientsSince(startDate, topTen);

        return IntStream.range(0, results.size())
                .mapToObj(i -> {
                    Object[] row = results.get(i);
                    String name = (String) row[0]; // 첫 번째 결과는 이름
                    long count = (Long) row[1];   // 두 번째 결과는 횟수

                    List<Item> items = itemRepository.findByName(name);


                    return new PopularIngredientDto(
                            i + 1,
                            name,
                            count
                    );
                })
                .collect(Collectors.toList());
    }

    public List<PopularRecipeDto> getPopularRecipes(String period, User user) {
        List<PopularRecipeDto> popularRecipes;

        if ("weekly".equals(period)) {
            popularRecipes = recipeRepository.findPopularAiRecipesSince(LocalDateTime.now().minusWeeks(1));
        } else if ("monthly".equals(period)) {
            popularRecipes = recipeRepository.findPopularAiRecipesSince(LocalDateTime.now().minusMonths(1));
        } else {
            popularRecipes = recipeRepository.findPopularAiRecipes();
        }

        if (user != null) {
            popularRecipes.forEach(dto -> {
                boolean isLiked = likeRepository.existsByRecipeIdAndUserId(dto.getId(), user.getId());
                dto.setLiked(isLiked);
            });
        }
        return popularRecipes;
    }
}