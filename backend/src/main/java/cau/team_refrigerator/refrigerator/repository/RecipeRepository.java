package cau.team_refrigerator.refrigerator.repository;

import cau.team_refrigerator.refrigerator.domain.Recipe;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface RecipeRepository extends JpaRepository<Recipe, Long> {

    // ⭐️ 사용자 레시피 필터링 로직이 추가된 새로운 메서드
    // isUserOnly가 TRUE일 경우, r.isCustom=TRUE(사용자 레시피)만 조회합니다.
    @Query("SELECT r FROM Recipe r LEFT JOIN r.likes l WITH l.createdAt >= :startDate " +
            "WHERE (:isUserOnly = FALSE OR r.isCustom = TRUE) " +
            "GROUP BY r.id " +
            "ORDER BY COUNT(l) DESC")
    List<Recipe> findPopularRecipesByPeriodAndType(
            @Param("startDate") LocalDateTime startDate,
            @Param("isUserOnly") boolean isUserOnly);

    boolean existsByApiRecipeId(String apiRecipeId);

    List<Recipe> findByIsCustomFalse();

    @Query("SELECT r FROM Recipe r WHERE r.id = :id")
    Optional<Recipe> findByIdIgnoringFilters(@Param("id") Long id);

    // AI 레시피 순위 (전체 기간)
    @Query("SELECT r FROM Recipe r LEFT JOIN r.likes l WHERE r.isCustom = false GROUP BY r.id ORDER BY COUNT(l) DESC")
    List<Recipe> findPopularAiRecipes();

    // AI 레시피 순위 (기간별)
    @Query("SELECT r FROM Recipe r LEFT JOIN r.likes l WITH l.createdAt >= :startDate WHERE r.isCustom = false GROUP BY r.id ORDER BY COUNT(l) DESC")
    List<Recipe> findPopularAiRecipesSince(@Param("startDate") LocalDateTime startDate);

    @Query("SELECT DISTINCT r FROM Recipe r JOIN r.recipeIngredients ri WHERE ri.ingredient.id IN :ingredientIds AND r.isCustom = false")
    List<Recipe> findRecipesWithAnyIngredientIds(@Param("ingredientIds") List<Long> ingredientIds);

    List<Recipe> findByTitleContaining(String title);
}