// /dto/GptIngredientDto.java

package cau.team_refrigerator.refrigerator.domain.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true) // JSON에 모르는 필드가 있어도 무시
public class GptIngredientDto {
    private String name;
    private int quantity = 1; // 기본값
    private String unit = "개"; // 기본값
    private String category;
    private String expirationDate; // GPT는 String (YYYY-MM-DD 또는 null)로 줌
}