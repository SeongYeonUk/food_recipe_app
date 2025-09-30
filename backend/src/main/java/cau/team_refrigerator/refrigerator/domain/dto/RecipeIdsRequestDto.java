package cau.team_refrigerator.refrigerator.domain.dto;

import lombok.Getter;
import java.util.List;

// 일괄적으로 추가하기 위함
@Getter
public class RecipeIdsRequestDto {
    private List<Long> recipeIds;
}