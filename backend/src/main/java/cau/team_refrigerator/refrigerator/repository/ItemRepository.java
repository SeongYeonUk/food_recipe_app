package cau.team_refrigerator.refrigerator.repository;

import cau.team_refrigerator.refrigerator.domain.Item;
import cau.team_refrigerator.refrigerator.domain.Refrigerator;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.time.LocalDate;
import java.util.Optional;

public interface ItemRepository extends JpaRepository<Item, Long> {

     // 특정 냉장고에 있는 모든 식재료를 찾는 메소드
    List<Item> findAllByRefrigeratorId(Long refrigerator);
    List<Item> findByName(String name);
    @Query("SELECT i.name FROM Item i " +
            "WHERE i.refrigerator.user.id = :userId " +
            "AND i.expiryDate <= :targetDate")
    List<String> findNamesByUserIdAndExpiringBefore(@Param("userId") Long userId,
                                                    @Param("targetDate") LocalDate targetDate);
    // 대체 재료(리스트) 중 내 냉장고에 있는 것 조회
    @Query("SELECT DISTINCT i.name FROM Item i WHERE i.refrigerator.user.id = :userId AND i.name IN :names")
    List<String> findNamesByUserIdAndNamesIn(@Param("userId") Long userId, @Param("names") List<String> names);

}
