package cau.team_refrigerator.refrigerator.domain.dto;

import cau.team_refrigerator.refrigerator.domain.AllergyIngredient;
import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class AllergyIngredientResponseDto {
    private Long id;
    private Long ingredientId;
    private String name;

    public static AllergyIngredientResponseDto from(AllergyIngredient entity) {
        Long ingredientId = entity.getIngredient() != null ? entity.getIngredient().getId() : null;
        return new AllergyIngredientResponseDto(entity.getId(), ingredientId, entity.getName());
    }
}
