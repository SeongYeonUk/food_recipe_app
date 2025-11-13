package cau.team_refrigerator.refrigerator.repository;

import cau.team_refrigerator.refrigerator.domain.Post;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.domain.Sort; // Sort import
import java.util.List;

public interface PostRepository extends JpaRepository<Post, Long> {

    // ⬇️ [핵심 수정] DTO 변환에 필요한 모든 LAZY 필드를 미리 로드합니다. ⬇️
    @Query("SELECT p FROM Post p " +
            "JOIN FETCH p.user u " +        // User 엔티티 강제 로드
            "LEFT JOIN FETCH p.likes l " +   // Likes 컬렉션 강제 로드
            "LEFT JOIN FETCH p.dislikes d " + // Dislikes 컬렉션 강제 로드
            "LEFT JOIN FETCH p.reviews r")   // Reviews 컬렉션 강제 로드
    List<Post> findAllWithDetails(Sort sort);
    // ⬆️ [핵심 수정] ⬆️
}