// src/main/java/cau/team_refrigerator/refrigerator/repository/HiddenRecipeRepository.java

package cau.team_refrigerator.refrigerator.repository;

import cau.team_refrigerator.refrigerator.domain.HiddenRecipe;
import cau.team_refrigerator.refrigerator.domain.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface HiddenRecipeRepository extends JpaRepository<HiddenRecipe, Long> {
    // 특정 사용자가 숨긴 모든 레시피 목록을 찾는 메소드
    List<HiddenRecipe> findAllByUser(User user);
}