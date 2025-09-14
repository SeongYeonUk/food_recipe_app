package cau.team_refrigerator.refrigerator.repository;

import cau.team_refrigerator.refrigerator.domain.Dislike;
import cau.team_refrigerator.refrigerator.domain.Recipe;
import cau.team_refrigerator.refrigerator.domain.User;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DislikeRepository extends JpaRepository<Dislike, Long> {

    // 특정 유저가 특정 레시피에 싫어요를 눌렀는지 확인
    boolean existsByUserAndRecipe(User user, Recipe recipe);

    // 특정 유저가 특정 레시피에 누른 싫어요를 삭제
    void deleteByUserAndRecipe(User user, Recipe recipe);
}