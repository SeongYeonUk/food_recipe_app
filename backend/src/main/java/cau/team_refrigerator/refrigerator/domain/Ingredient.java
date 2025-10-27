package cau.team_refrigerator.refrigerator.domain;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@Entity
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Table(name = "ingredient") // 테이블 이름: ingredient
// 재료 정보만을 담음
public class Ingredient {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 재료 이름 (예: "마늘", "소금")
    // unique = true 로 설정해서 중복된 재료 이름이 저장되지 않도록 함
    @Column(nullable = false, unique = true)
    private String name;

    // Ingredient 와 RecipeIngredient 사이의 관계 설정 (1:N)
    @OneToMany(mappedBy = "ingredient", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<RecipeIngredient> recipeIngredients = new ArrayList<>();
}