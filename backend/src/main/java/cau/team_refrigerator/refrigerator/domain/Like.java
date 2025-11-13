package cau.team_refrigerator.refrigerator.domain;

import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;
import java.time.LocalDateTime;

@Entity
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
// ⬇️ @UniqueConstraint 를 제거했습니다!
@Table(name = "likes")
public class Like {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "like_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recipe_id")
    private Recipe recipe; // (Post에 좋아요 누를 땐 null이 됩니다)

    // --- ⬇️ '레시피 자랑' 글과 연결하기 위해 추가 ⬇️ ---
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "post_id")
    private Post post; // (Recipe에 좋아요 누를 땐 null이 됩니다)
    // --- ⬆️ 여기까지 추가 ⬆️ ---

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    // 기존 생성자 (Recipe용)
    public Like(User user, Recipe recipe) {
        this.user = user;
        this.recipe = recipe;
        this.post = null; // 명시적으로 null 처리
    }

    // --- ⬇️ Post용 생성자 추가 ⬇️ ---
    public Like(User user, Post post) {
        this.user = user;
        this.recipe = null; // 명시적으로 null 처리
        this.post = post;
    }
    // --- ⬆️ 여기까지 추가 ⬆️ ---
}