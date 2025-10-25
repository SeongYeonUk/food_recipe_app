package cau.team_refrigerator.refrigerator.domain.dto;

import lombok.Getter;
import lombok.Setter;
import lombok.AllArgsConstructor;

@Getter
@Setter
public class PopularIngredientDto {
    private int rank;
    private String name;
    private long count;

    public PopularIngredientDto(int rank, String name, long count) {
        this.rank = rank;
        this.name = name;
        this.count = count;
    }
}