// src/main/java/cau/team_refrigerator/refrigerator/domain/HiddenRecipe.java

package cau.team_refrigerator.refrigerator.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@NoArgsConstructor
public class HiddenRecipe {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recipe_id", nullable = false)
    private Recipe recipe;

    public HiddenRecipe(User user, Recipe recipe) {
        this.user = user;
        this.recipe = recipe;
    }
}