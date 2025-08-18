package cau.team_refrigerator.refrigerator.repository;

import cau.team_refrigerator.refrigerator.domain.Item;
import cau.team_refrigerator.refrigerator.domain.Refrigerator;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ItemRepository extends JpaRepository<Item, Long> {

     // 특정 냉장고에 있는 모든 식재료를 찾는 메소드
    List<Item> findAllByRefrigeratorId(Long refrigerator);
}