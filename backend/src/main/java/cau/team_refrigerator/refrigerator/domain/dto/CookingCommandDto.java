package cau.team_refrigerator.refrigerator.domain.dto;

import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class CookingCommandDto {
    private String intent;       // "START", "NEXT", "PREVIOUS", "TIMER"
    private Integer timerSeconds; // 타이머 시간 (초 단위)
    private String recipeName;    // 요리 시작 시 레시피 이름
    private String targetIngredient;
}