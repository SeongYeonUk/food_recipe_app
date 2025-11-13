package cau.team_refrigerator.refrigerator.domain.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class AllergyIngredientRequestDto {
    private Long ingredientId;
    private String name;
}
