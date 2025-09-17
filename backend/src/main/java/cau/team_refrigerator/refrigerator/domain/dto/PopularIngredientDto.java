package cau.team_refrigerator.refrigerator.domain.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class PopularIngredientDto {
    private String name;
    private long count;
    private String coupangUrl;

    public PopularIngredientDto(String name, long count) {
        this.name = name;
        this.count = count;
    }
}