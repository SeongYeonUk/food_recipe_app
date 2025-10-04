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

    List<Recipe> findByIsCustomFalse();

    @Query("SELECT r FROM Recipe r WHERE r.id = :id")
    Optional<Recipe> findByIdIgnoringFilters(@Param("id") Long id);

    // 이 쿼리는 완벽합니다!
    @Query("SELECT r FROM Recipe r LEFT JOIN r.likes l WHERE r.isCustom = false GROUP BY r.id ORDER BY COUNT(l) DESC")
    List<Recipe> findPopularAiRecipes();

    // 👇👇👇 'Since'가 붙은 메서드의 쿼리만 아래와 같이 수정해주세요. 👇👇👇
    // [수정 이유] 날짜 조건을 ON 절(WITH 키워드)로 옮겨서, 해당 기간에 좋아요가 없는 레시피도 순위에 포함되도록 합니다.
    @Query("SELECT r FROM Recipe r LEFT JOIN r.likes l WITH l.createdAt >= :startDate WHERE r.isCustom = false GROUP BY r.id ORDER BY COUNT(l) DESC")
    List<Recipe> findPopularAiRecipesSince(@Param("startDate") LocalDateTime startDate);
}