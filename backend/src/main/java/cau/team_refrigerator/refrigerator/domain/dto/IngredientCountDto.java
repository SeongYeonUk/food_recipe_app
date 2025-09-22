package cau.team_refrigerator.refrigerator.domain.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class IngredientCountDto {
    private String name;
    private long count;
}