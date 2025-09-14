package cau.team_refrigerator.refrigerator.repository;

import cau.team_refrigerator.refrigerator.domain.Favorite;
import cau.team_refrigerator.refrigerator.domain.Recipe;
import cau.team_refrigerator.refrigerator.domain.User; // User 임포트
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;


public interface FavoriteRepository extends JpaRepository<Favorite, Long> {

    // User 객체를 받아서 해당 유저의 모든 Favorite 목록을 찾아오는 메소드
    List<Favorite> findAllByUser(User user);

    // User와 Recipe ID를 받아서 해당하는 Favorite 데이터를 삭제하는 메소드
    void deleteByUserAndRecipeId(User user, Long recipeId);

    boolean existsByUserAndRecipe(User user, Recipe recipe);

    // Favorite 개수를 세는 메소드
    long countByRecipe(Recipe recipe);

    // 여러 개의 recipeId와 user로 한 번에 삭제하는 메소드
    @Modifying
    @Query("DELETE FROM Favorite f WHERE f.user = :user AND f.recipe.id IN :recipeIds")
    void deleteAllByUserAndRecipeIds(@Param("user") User user, @Param("recipeIds") List<Long> recipeIds);
}