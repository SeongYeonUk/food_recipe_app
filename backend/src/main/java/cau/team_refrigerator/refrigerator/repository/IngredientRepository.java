// src/main/java/cau/team_refrigerator/refrigerator/repository/IngredientRepository.java
package cau.team_refrigerator.refrigerator.repository;

import cau.team_refrigerator.refrigerator.domain.Ingredient;
import org.springframework.data.jpa.repository.JpaRepository;

import javax.swing.*;
import java.util.List; // 👈 List 임포트 추가
import java.util.Optional;
import java.time.LocalDate;

public interface IngredientRepository extends JpaRepository<Ingredient, Long> {
    Optional<Ingredient> findByName(String name);

    // 👇👇👇 [신규 추가] 여러 이름으로 Ingredient 리스트 찾기 👇👇👇
    List<Ingredient> findAllByNameIn(List<String> names);


}