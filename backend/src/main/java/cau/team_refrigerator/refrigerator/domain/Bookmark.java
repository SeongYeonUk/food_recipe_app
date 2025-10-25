package cau.team_refrigerator.refrigerator.domain;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Bookmark {

    // (id, user 필드는 동일)
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @Column(nullable = false)
    private Long recipeId;

    @Column(nullable = false)
    private String recipeType; // Enum 대신 String 타입으로 변경

    public Bookmark(User user, Long recipeId, String recipeType) {
        this.user = user;
        this.recipeId = recipeId;
        this.recipeType = recipeType;
    }
}
