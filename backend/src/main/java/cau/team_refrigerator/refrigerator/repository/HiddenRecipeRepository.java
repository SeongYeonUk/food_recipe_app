// src/main/java/cau/team_refrigerator/refrigerator/repository/HiddenRecipeRepository.java

package cau.team_refrigerator.refrigerator.repository;

import cau.team_refrigerator.refrigerator.domain.HiddenRecipe;
import cau.team_refrigerator.refrigerator.domain.Recipe;
import cau.team_refrigerator.refrigerator.domain.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface HiddenRecipeRepository extends JpaRepository<HiddenRecipe, Long> {
    // 특정 사용자가 숨긴 모든 레시피 목록을 찾는 메소드
    List<HiddenRecipe> findAllByUser(User user);

    // 특정 유저가 특정 레시피를 숨겼는지 확인하는 메소드
    boolean existsByUserAndRecipe(User user, Recipe recipe);

    // 여러 개의 recipeId와 user로 한 번에 삭제하는 메소드
    @Modifying
    @Query("DELETE FROM HiddenRecipe h WHERE h.user = :user AND h.recipe.id IN :recipeIds")
    void deleteAllByUserAndRecipeIds(@Param("user") User user, @Param("recipeIds") List<Long> recipeIds);
}