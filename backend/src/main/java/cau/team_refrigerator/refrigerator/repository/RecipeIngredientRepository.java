package cau.team_refrigerator.refrigerator.repository;

import cau.team_refrigerator.refrigerator.domain.RecipeIngredient;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RecipeIngredientRepository extends JpaRepository<RecipeIngredient, Long> {
}