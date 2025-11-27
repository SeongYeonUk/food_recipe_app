package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.domain.Item;
import cau.team_refrigerator.refrigerator.domain.Recipe;
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

    // 💡 레시피 조회 로직을 수정했습니다.
    public List<PopularRecipeDto> getPopularRecipes(String period, String type, User user) {
        LocalDateTime startDate;

        // 1. 기간(period) 설정
        if ("weekly".equalsIgnoreCase(period)) {
            startDate = LocalDateTime.now().minusWeeks(1);
        } else if ("monthly".equalsIgnoreCase(period)) {
            startDate = LocalDateTime.now().minusMonths(1);
        } else {
            // "overall" 또는 기타 경우: 매우 먼 과거부터 시작
            startDate = LocalDateTime.of(2000, 1, 1, 0, 0);
        }

        // 2. 💡 타입(type) 설정: "user_only" 요청 시 사용자 레시피만 조회하도록 플래그 설정
        boolean isUserOnly = "user_only".equalsIgnoreCase(type);

        // 3. Repository로부터 Recipe 엔티티 목록을 받습니다.
        // 이 메서드(`findPopularRecipesByPeriodAndType`)는 RecipeRepository에 새로 정의되어야 하며,
        // isUserOnly 플래그에 따라 AI 레시피를 필터링하는 쿼리를 실행해야 합니다.
        List<Recipe> popularRecipeEntities =
                recipeRepository.findPopularRecipesByPeriodAndType(startDate, isUserOnly);


        // 4. Recipe 엔티티 목록을 순회하며 '최신 정보'로 PopularRecipeDto를 만듭니다.
        return popularRecipeEntities.stream().map(recipe -> {
            // 4-1. 실시간 '좋아요' 수를 직접 조회합니다.
            long freshLikeCount = likeRepository.countByRecipeId(recipe.getId());

            // 4-2. 현재 사용자의 '좋아요' 여부를 직접 확인합니다.
            boolean isLiked = (user != null) && likeRepository.existsByRecipeIdAndUserId(recipe.getId(), user.getId());

            // 4-3. DTO를 새로 생성하고 최신 상태를 설정합니다.
            PopularRecipeDto dto = new PopularRecipeDto(
                    recipe.getId(),
                    recipe.getTitle(),
                    recipe.getImageUrl(),
                    freshLikeCount
            );
            dto.setLiked(isLiked);

            return dto;
        }).collect(Collectors.toList());
    }
}