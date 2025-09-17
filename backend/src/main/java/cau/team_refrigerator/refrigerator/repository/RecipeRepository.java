package cau.team_refrigerator.refrigerator.repository;

import cau.team_refrigerator.refrigerator.domain.Recipe;
import cau.team_refrigerator.refrigerator.domain.dto.PopularRecipeDto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.time.LocalDateTime;

@Repository
public interface RecipeRepository extends JpaRepository<Recipe, Long> {

    @Query("SELECT new cau.team_refrigerator.refrigerator.domain.dto.PopularRecipeDto(r.id, r.title, r.imageUrl, COUNT(l)) " +
            "FROM Recipe r LEFT JOIN r.likes l " +
            "GROUP BY r.id " +
            "ORDER BY COUNT(l) DESC " +
            "LIMIT 10")
    List<PopularRecipeDto> findPopularRecipes();

    @Query("SELECT new cau.team_refrigerator.refrigerator.domain.dto.PopularRecipeDto(r.id, r.title, r.imageUrl, COUNT(l)) " +
            "FROM Recipe r LEFT JOIN r.likes l " +
            "WHERE l.createdAt >= :startDate " +
            "GROUP BY r.id " +
            "ORDER BY COUNT(l) DESC " +
            "LIMIT 10")
    List<PopularRecipeDto> findPopularRecipesSince(@Param("startDate") LocalDateTime startDate);
}