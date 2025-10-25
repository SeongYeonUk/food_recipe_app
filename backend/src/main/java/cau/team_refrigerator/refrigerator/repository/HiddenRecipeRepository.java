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
    List<HiddenRecipe> findAllByUser(User user);
    boolean existsByUserAndRecipe(User user, Recipe recipe);

    @Modifying
    @Query("DELETE FROM HiddenRecipe h WHERE h.user = :user AND h.recipe.id IN :recipeIds")
    void deleteAllByUserAndRecipeIds(@Param("user") User user, @Param("recipeIds") List<Long> recipeIds);

    // [최종 솔루션] Service에서 사용할 수 있도록 메소드를 추가합니다.
    @Modifying
    @Query("DELETE FROM HiddenRecipe h WHERE h.recipe = :recipe")
    void deleteByRecipe(@Param("recipe") Recipe recipe);
}

