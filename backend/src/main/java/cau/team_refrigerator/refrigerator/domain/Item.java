package cau.team_refrigerator.refrigerator.domain;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import java.time.LocalDate;

@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
@Table(name = "items")
public class Item {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "item_id")
    private Long id; // 식재료의 고유 ID

    @Column(nullable = false)
    private String name; // 식재료명

    private LocalDate registrationDate; // 등록일

    private LocalDate expiryDate; // 유통기한

    private int quantity; // 수량

    @Enumerated(EnumType.STRING) // Enum 타입을 문자열로 저장
    private ItemCategory category; // 카테고리

    // 어떤 냉장고에 속해있는지 (다대일 관계)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "refrigerator_id")
    private Refrigerator refrigerator;

    @Builder
    public Item(String name, LocalDate registrationDate, LocalDate expiryDate, int quantity, ItemCategory category, Refrigerator refrigerator) {
        this.name = name;
        this.registrationDate = registrationDate;
        this.expiryDate = expiryDate;
        this.quantity = quantity;
        this.category = category;
        this.refrigerator = refrigerator;
    }

    public void update(String name, LocalDate expiryDate, int quantity, ItemCategory category)
    {
        this.name = name;
        this.expiryDate = expiryDate;
        this.quantity = quantity;
        this.category = category;
    }
}