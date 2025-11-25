package cau.team_refrigerator.refrigerator.domain;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Table(name = "recipe_ingredient")
public class RecipeIngredient {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Recipe 관계 (N:1)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recipe_id", nullable = false)
    private Recipe recipe;

    // Ingredient 관계 (N:1)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ingredient_id", nullable = false)
    private Ingredient ingredient;

    // "10g", "1/2컵" 등 원문 수량 텍스트
    @Column(nullable = true)
    private String amount;

    // 계산된 g/영양/가격 (DB 스크립트에서 채워 넣음)
    @Column(name = "estimated_grams")
    private Double estimatedGrams;

    @Column(name = "line_kcal")
    private Double lineKcal;

    @Column(name = "line_carbs_g")
    private Double lineCarbsG;

    @Column(name = "line_protein_g")
    private Double lineProteinG;

    @Column(name = "line_fat_g")
    private Double lineFatG;

    @Column(name = "line_sodium_mg")
    private Double lineSodiumMg;

    @Column(name = "line_min_price_krw")
    private Double lineMinPriceKrw;

    @Column(name = "line_max_price_krw")
    private Double lineMaxPriceKrw;
}
