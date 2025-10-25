package cau.team_refrigerator.refrigerator.repository;

import cau.team_refrigerator.refrigerator.domain.Bookmark;
import org.springframework.data.jpa.repository.JpaRepository;
import cau.team_refrigerator.refrigerator.domain.User;

import java.util.List;
import java.util.Optional;

public interface BookmarkRepository extends JpaRepository<Bookmark, Long> {

    Optional<Bookmark> findByUserAndRecipeIdAndRecipeType(User user, Long recipeId, String recipeType); // String으로 변경

    // findAllByUser는 변경 없음
    List<Bookmark> findAllByUser(User user);
}