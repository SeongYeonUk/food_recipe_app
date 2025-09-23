package cau.team_refrigerator.refrigerator.domain.dto;

import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import java.util.List;
import lombok.AllArgsConstructor;

@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RecipeIntegrationResponseDto {

    private String recipeName;
    private String summary;
    private String cookingTime;
    private String calorie;

    private List<String> ingredients; // 재료명과 용량을 합친 리스트
    private List<String> instructions; // 조리 과정 리스트

}