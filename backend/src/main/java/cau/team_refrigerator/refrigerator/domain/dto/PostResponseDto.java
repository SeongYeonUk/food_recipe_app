package cau.team_refrigerator.refrigerator.domain.dto;

import cau.team_refrigerator.refrigerator.domain.Post;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
public class PostResponseDto {

    private Long postId;
    private String authorName; // 작성자 닉네임 (또는 이름)
    private String title;
    private String content;
    private String cookTime;
    private String ingredients;
    private String imageUrl;
    private LocalDateTime createdAt;
    private int likeCount;      // '좋아요' 개수
    private int dislikeCount;   // '싫어요' 개수
    private int reviewCount;    // '후기' 개수

    // Entity를 DTO로 변환하는 생성자
    public PostResponseDto(Post post) {
        this.postId = post.getId();

        // User 엔티티에 getNickname()이나 getName() 등
        // 사용자 이름을 가져올 메서드가 있다고 가정합니다.
        // 없다면 post.getUser().getEmail() 등으로 수정해야 합니다.
        this.authorName = post.getUser().getNickname(); // <- 이 부분 확인 필요

        this.title = post.getTitle();
        this.content = post.getContent();
        this.cookTime = post.getCookTime();
        this.ingredients = post.getIngredients();
        this.imageUrl = post.getImageUrl();
        this.createdAt = post.getCreatedAt();

        // Post 엔티티에 만들어둔 카운트 메서드 호출
        this.likeCount = post.getLikeCount();
        this.dislikeCount = post.getDislikeCount();
        this.reviewCount = post.getReviewCount();
    }
}