package cau.team_refrigerator.refrigerator.repository;

import cau.team_refrigerator.refrigerator.domain.Like;
import cau.team_refrigerator.refrigerator.domain.Recipe;
import cau.team_refrigerator.refrigerator.domain.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface LikeRepository extends JpaRepository<Like, Long>
{
    boolean existsByUserAndRecipe(User user, Recipe recipe);

    long countByRecipe(Recipe recipe);

    void deleteByUserAndRecipe(User user, Recipe recipe);

    // recipeId와 userId로 '좋아요' 기록이 존재하는지 확인 (존재하면 true, 없으면 false)
    boolean existsByRecipeIdAndUserId(Long recipeId, Long userId);

    // [최종 솔루션] Service에서 사용할 수 있도록 메소드를 추가합니다.
    @Modifying
    @Query("DELETE FROM Like l WHERE l.recipe = :recipe")
    void deleteByRecipe(@Param("recipe") Recipe recipe);
}
