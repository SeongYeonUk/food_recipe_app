package cau.team_refrigerator.refrigerator.repository;

import cau.team_refrigerator.refrigerator.domain.Favorite;
import cau.team_refrigerator.refrigerator.domain.User; // User 임포트
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface FavoriteRepository extends JpaRepository<Favorite, Long> {

    // User 객체를 받아서 해당 유저의 모든 Favorite 목록을 찾아오는 메소드
    List<Favorite> findAllByUser(User user);

    // User와 Recipe ID를 받아서 해당하는 Favorite 데이터를 삭제하는 메소드
    void deleteByUserAndRecipeId(User user, Long recipeId);
}