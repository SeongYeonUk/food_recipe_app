package cau.team_refrigerator.refrigerator.domain;

import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

// 필요한 import 구문들 (JPA 의존성이 추가되면 자동으로 인식됩니다)
import jakarta.persistence.*;

@Entity
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
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
    private Recipe recipe;

    public Like(User user, Recipe recipe) {
        this.user = user;
        this.recipe = recipe;
    }
}