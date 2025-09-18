package cau.team_refrigerator.refrigerator.repository;

import cau.team_refrigerator.refrigerator.domain.Recipe;
import cau.team_refrigerator.refrigerator.domain.dto.PopularRecipeDto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface RecipeRepository extends JpaRepository<Recipe, Long> {

    // [솔루션] 날짜 필터링 조건을 JOIN의 ON 절 안으로 이동시켜 LEFT JOIN이 올바르게 동작하도록 수정합니다.

    // AI 추천 레시피 대상 인기 순위 (전체 기간) - 이 쿼리는 수정할 필요 없음
    @Query("SELECT new cau.team_refrigerator.refrigerator.domain.dto.PopularRecipeDto(r.id, r.title, r.imageUrl, COUNT(l.id)) " +
            "FROM Recipe r LEFT JOIN Like l ON r.id = l.recipe.id " +
            "WHERE r.isCustom = false " +
            "GROUP BY r.id, r.title, r.imageUrl " +
            "ORDER BY COUNT(l.id) DESC")
    List<PopularRecipeDto> findPopularAiRecipes();

    // AI 추천 레시피 대상 인기 순위 (기간별) - 이 쿼리를 수정합니다.
    @Query("SELECT new cau.team_refrigerator.refrigerator.domain.dto.PopularRecipeDto(r.id, r.title, r.imageUrl, COUNT(l.id)) " +
            "FROM Recipe r " +
            // [수정] l.createdAt 조건을 WHERE가 아닌 ON 절 안으로 이동
            "LEFT JOIN Like l ON r.id = l.recipe.id AND l.createdAt >= :startDate " +
            "WHERE r.isCustom = false " +
            "GROUP BY r.id, r.title, r.imageUrl " +
            "ORDER BY COUNT(l.id) DESC")
    List<PopularRecipeDto> findPopularAiRecipesSince(@Param("startDate") LocalDateTime startDate);
}
