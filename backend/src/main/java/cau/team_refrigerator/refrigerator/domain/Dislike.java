package cau.team_refrigerator.refrigerator.domain;

import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import jakarta.persistence.*;

@Entity
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
// ⬇️ @UniqueConstraint 를 제거했습니다!
@Table(name = "dislikes")
public class Dislike {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "dislike_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recipe_id")
    private Recipe recipe;

    // --- ⬇️ '레시피 자랑' 글과 연결하기 위해 추가 ⬇️ ---
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "post_id")
    private Post post;
    // --- ⬆️ 여기까지 추가 ⬆️ ---

    // 기존 생성자 (Recipe용)
    public Dislike(User user, Recipe recipe) {
        this.user = user;
        this.recipe = recipe;
        this.post = null;
    }

    // --- ⬇️ Post용 생성자 추가 ⬇️ ---
    public Dislike(User user, Post post) {
        this.user = user;
        this.recipe = null;
        this.post = post;
    }
    // --- ⬆️ 여기까지 추가 ⬆️ ---
}