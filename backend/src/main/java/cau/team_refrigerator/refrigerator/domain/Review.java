package cau.team_refrigerator.refrigerator.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Entity
@Getter
@Setter
@NoArgsConstructor
@EntityListeners(AuditingEntityListener.class) // 생성 날짜 자동 관리를 위해 추가
public class Review {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "review_id")
    private Long id;

    @ManyToOne
    @JoinColumn(name = "post_id") // 실제 DB의 외래키 컬럼명
    private Post post;

    // ⭐️ 후기가 달릴 대상 레시피 (N:1)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recipe_id", nullable = false)
    private Recipe recipe;

    // ⭐️ 후기를 작성한 유저 (N:1)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private String title; // 후기 제목

    @Lob // 긴 텍스트
    @Column(nullable = false)
    private String content; // 후기 내용

    private String imageUrl; // 후기 이미지 (선택적)

    @CreatedDate
    @Column(updatable = false)
    private LocalDateTime createdAt;
}