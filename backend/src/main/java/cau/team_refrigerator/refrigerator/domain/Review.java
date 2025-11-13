package cau.team_refrigerator.refrigerator.domain;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@EntityListeners(AuditingEntityListener.class) // 생성 시간 자동 관리를 위해 추가
@Entity
public class Review { // '후기' 또는 '댓글' 엔티티

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "review_id")
    private Long id;

    @Lob // 댓글 내용이 길어질 수 있으므로
    @Column(nullable = false)
    private String content;

    // Review(N) : User(1)
    // 한 명의 유저는 여러 개의 후기를 작성할 수 있다.
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user; // 작성자

    // Review(N) : Post(1)
    // 하나의 게시글에는 여러 개의 후기가 달릴 수 있다.
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "post_id")
    private Post post; // 어느 게시글에 달린 후기인지

    @CreatedDate
    @Column(updatable = false)
    private LocalDateTime createdAt;

    @Builder
    public Review(String content, User user, Post post) {
        this.content = content;
        this.user = user;
        this.post = post;
    }

    // 후기 내용 수정 메서드
    public void update(String content) {
        this.content = content;
    }
}