package cau.team_refrigerator.refrigerator.domain.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class PostShareRequestDto {

    // "나만의 레시피"의 고유 ID
    private Long recipeId;
}