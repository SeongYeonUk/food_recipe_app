package cau.team_refrigerator.refrigerator.repository;

import cau.team_refrigerator.refrigerator.domain.IngredientStatics;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import java.util.List;

public interface IngredientStaticsRepository extends JpaRepository<IngredientStatics, Long> {
    // 전체 기간 기준, totalCount가 높은 순으로 상위 10개 조회
    @Query("SELECT s FROM IngredientStatics s JOIN FETCH s.item ORDER BY s.totalCount DESC LIMIT 10")
    List<IngredientStatics> findTop10ByOrderByTotalCountDesc();
}