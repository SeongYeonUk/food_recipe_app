package cau.team_refrigerator.refrigerator.repository;

import cau.team_refrigerator.refrigerator.domain.Dislike;
import cau.team_refrigerator.refrigerator.domain.Recipe;
import cau.team_refrigerator.refrigerator.domain.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface DislikeRepository extends JpaRepository<Dislike, Long> {
    boolean existsByUserAndRecipe(User user, Recipe recipe);

    Optional<Dislike> findByUserAndRecipe(User user, Recipe recipe);
    void deleteByUserAndRecipe(User user, Recipe recipe);
    long countByRecipe(Recipe recipe);
    List<Dislike> findAllByUser(User user);

    // [최종 솔루션] Service에서 사용할 수 있도록 메소드를 추가합니다.
    @Modifying
    @Query("DELETE FROM Dislike d WHERE d.recipe = :recipe")
    void deleteByRecipe(@Param("recipe") Recipe recipe);
}
