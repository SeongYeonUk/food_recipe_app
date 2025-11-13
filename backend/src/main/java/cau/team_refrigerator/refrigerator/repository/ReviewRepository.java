package cau.team_refrigerator.refrigerator.repository;

import cau.team_refrigerator.refrigerator.domain.Post;
import cau.team_refrigerator.refrigerator.domain.Review;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List; // List import

public interface ReviewRepository extends JpaRepository<Review, Long> {

    // 특정 게시글(Post)에 달린 모든 후기(Review)를 찾는 메서드
    // (JPA가 메서드 이름을 분석해서 자동으로 쿼리를 만들어줍니다)
    List<Review> findAllByPost(Post post);
}