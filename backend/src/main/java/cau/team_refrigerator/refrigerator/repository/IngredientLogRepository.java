package cau.team_refrigerator.refrigerator.repository;

import cau.team_refrigerator.refrigerator.domain.IngredientLog;
import cau.team_refrigerator.refrigerator.domain.dto.PopularIngredientDto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface IngredientLogRepository extends JpaRepository<IngredientLog, Long> {


    // 전체 기간 집계
    @Query("SELECT new cau.team_refrigerator.refrigerator.domain.dto.PopularIngredientDto(i.ingredientName, COUNT(i)) " +
            "FROM IngredientLog i " +
            "GROUP BY i.ingredientName " +
            "ORDER BY COUNT(i) DESC")
    List<PopularIngredientDto> findPopularIngredients();

    // 특정 기간 집계 (주간/월간)
    @Query("SELECT new cau.team_refrigerator.refrigerator.domain.dto.PopularIngredientDto(i.ingredientName, COUNT(i)) " +
            "FROM IngredientLog i " +
            "WHERE i.createdAt >= :startDate " +
            "GROUP BY i.ingredientName " +
            "ORDER BY COUNT(i) DESC")
    List<PopularIngredientDto> findPopularIngredientsSince(@Param("startDate") LocalDateTime startDate);
}