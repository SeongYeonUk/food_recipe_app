package cau.team_refrigerator.refrigerator.repository;

import cau.team_refrigerator.refrigerator.domain.IngredientLog;
import cau.team_refrigerator.refrigerator.domain.dto.IngredientCountDto;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface IngredientLogRepository extends JpaRepository<IngredientLog, Long> {
    @Query("SELECT il.item.name, COUNT(il.item.id) " +
            "FROM IngredientLog il " +
            "WHERE il.createdAt >= :startDate " +
            "GROUP BY il.item.name " +
            "ORDER BY COUNT(il.item.id) DESC")
    List<Object[]> findPopularIngredientsSince(@Param("startDate") LocalDateTime startDate, Pageable pageable);
}
