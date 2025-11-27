package cau.team_refrigerator.refrigerator.domain.dto;

import cau.team_refrigerator.refrigerator.domain.Review;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
public class ReviewResponseDto {

    private Long reviewId;
    private String title;
    private String content;
    private String imageUrl;
    private String authorNickname; // ⭐️ 작성자 닉네임
    private LocalDateTime createdAt;
    private boolean isMine; // ⭐️ 내가 쓴 글인지 여부

    // 엔티티를 DTO로 변환하는 생성자
    public ReviewResponseDto(Review review, Long currentUserId) {
        this.reviewId = review.getId();
        this.title = review.getTitle();
        this.content = review.getContent();
        this.imageUrl = review.getImageUrl();
        this.authorNickname = review.getUser().getNickname(); // User 엔티티에서 닉네임 가져오기
        this.createdAt = review.getCreatedAt();
        this.isMine = review.getUser().getId().equals(currentUserId); // ⭐️ 현재 사용자와 작성자 ID 비교
    }
}