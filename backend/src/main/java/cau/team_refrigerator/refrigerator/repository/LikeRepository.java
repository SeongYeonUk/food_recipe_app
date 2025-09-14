package cau.team_refrigerator.refrigerator.repository;

import cau.team_refrigerator.refrigerator.domain.Like;
import cau.team_refrigerator.refrigerator.domain.Recipe;
import cau.team_refrigerator.refrigerator.domain.User;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LikeRepository extends JpaRepository<Like, Long> {

    // 특정 유저가 특정 레시피에 좋아요를 눌렀는지 확인
    boolean existsByUserAndRecipe(User user, Recipe recipe);

    // 특정 레시피에 눌린 좋아요 총 개수 확인
    long countByRecipe(Recipe recipe);

    void deleteByUserAndRecipe(User user, Recipe recipe);
}