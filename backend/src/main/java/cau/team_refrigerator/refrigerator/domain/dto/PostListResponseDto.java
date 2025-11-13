package cau.team_refrigerator.refrigerator.domain.dto;

import cau.team_refrigerator.refrigerator.domain.Post;
import lombok.Getter;

@Getter
public class PostListResponseDto {

    private Long postId;
    private String title;       // "계란말이", "김치볶음밥"
    private String imageUrl;    // 썸네일 이미지 URL
    private String authorName;  // 작성자 닉네임
    private int likeCount;      // '좋아요' 수 (정렬에 사용 가능)
    private int reviewCount;    // '후기' 수

    // Post 엔티티를 List용 DTO로 변환하는 생성자
    public PostListResponseDto(Post post) {
        this.postId = post.getId();
        this.title = post.getTitle();
        this.imageUrl = post.getImageUrl();
        // (주의!) User 엔티티에 getNickname()이 있다고 가정합니다.
        this.authorName = post.getUser().getNickname();
        this.likeCount = post.getLikeCount();
        this.reviewCount = post.getReviewCount();
    }
}