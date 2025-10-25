package cau.team_refrigerator.refrigerator.repository;

import cau.team_refrigerator.refrigerator.domain.Favorite;
import cau.team_refrigerator.refrigerator.domain.Recipe;
import cau.team_refrigerator.refrigerator.domain.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
// [최종 솔루션] Transactional import를 사용하지 않습니다.

public interface FavoriteRepository extends JpaRepository<Favorite, Long> {

    Optional<Favorite> findByUserAndRecipe(User user, Recipe recipe);

    List<Favorite> findAllByUser(User user);

    boolean existsByUserAndRecipe(User user, Recipe recipe);

    long countByRecipe(Recipe recipe);

    void deleteByUserAndRecipe(User user, Recipe recipe);

    // [최종 솔루션] @Transactional을 제거합니다. 모든 트랜잭션 관리는 Service가 책임집니다.
    @Modifying
    @Query("DELETE FROM Favorite f WHERE f.user = :user AND f.recipe.id IN :recipeIds")
    void deleteAllByUserAndRecipeIds(@Param("user") User user, @Param("recipeIds") List<Long> recipeIds);

    // [최종 솔루션] @Transactional을 제거합니다.
    @Modifying
    @Query("DELETE FROM Favorite f WHERE f.recipe = :recipe")
    void deleteByRecipe(@Param("recipe") Recipe recipe);
}
