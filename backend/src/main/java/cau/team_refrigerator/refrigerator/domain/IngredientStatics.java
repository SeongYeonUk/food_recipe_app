package cau.team_refrigerator.refrigerator.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@NoArgsConstructor
public class IngredientStatics {

    @Id
    private Long itemId; // 식재료(Item)의 ID와 동일하게 사용

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId // itemId를 FK이면서 PK로 매핑
    @JoinColumn(name = "item_id")
    private Item item;

    private long totalCount;

    public IngredientStatics(Item item) {
        this.item = item;
        this.totalCount = 0;
    }

    // 카운트 증가를 위한 편의 메소드
    public void incrementCount() {
        this.totalCount++;
    }
}