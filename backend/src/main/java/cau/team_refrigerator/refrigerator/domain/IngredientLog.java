package cau.team_refrigerator.refrigerator.domain;

import jakarta.persistence.*;
import lombok.*; // Getter, NoArgsConstructor 추가
import org.hibernate.annotations.CreationTimestamp;
import java.time.LocalDateTime;

@Entity
@Getter // 추가
@Builder
@AllArgsConstructor
@NoArgsConstructor(access = AccessLevel.PROTECTED) // 추가
@Table(name = "ingredient_log")
public class IngredientLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "item_id", nullable = false)
    private Item item;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    // --- 아래 직접 작성한 생성자는 삭제 ---
    // public IngredientLog() { } // @NoArgsConstructor가 대체
    // public IngredientLog(Item item, User user) { } // @AllArgsConstructor와 @Builder가 대체
}