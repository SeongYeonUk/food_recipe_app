package cau.team_refrigerator.refrigerator.domain.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class RecipeCreateRequestDto
{
    private String title;
    private String ingredients;
    private String instructions;
    private Integer time;
    private String imageUrl;
}