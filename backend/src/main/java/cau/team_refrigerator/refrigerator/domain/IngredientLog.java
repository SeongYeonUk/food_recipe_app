package cau.team_refrigerator.refrigerator.domain;
import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;
import java.time.LocalDateTime;

@Entity
@Table(name = "ingredient_log")
public class IngredientLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "ingredient_name", nullable = false)
    private String ingredientName;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    // 기본 생성자 (JPA는 기본 생성자가 꼭 필요)
    public IngredientLog() {
    }

    // 인자 2개를 받는 생성자
    public IngredientLog(String ingredientName, User user) {
        this.ingredientName = ingredientName;
        this.user = user;
    }

}