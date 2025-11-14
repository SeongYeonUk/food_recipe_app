package cau.team_refrigerator.refrigerator.repository;

import cau.team_refrigerator.refrigerator.domain.AllergyIngredient;
import cau.team_refrigerator.refrigerator.domain.Ingredient;
import cau.team_refrigerator.refrigerator.domain.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface AllergyIngredientRepository extends JpaRepository<AllergyIngredient, Long> {

    List<AllergyIngredient> findAllByUserOrderByCreatedAtAsc(User user);

    boolean existsByUserAndIngredient(User user, Ingredient ingredient);

    Optional<AllergyIngredient> findByIdAndUser(Long id, User user);
}
