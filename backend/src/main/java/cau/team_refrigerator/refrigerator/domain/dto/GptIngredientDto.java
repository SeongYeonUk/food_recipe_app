package cau.team_refrigerator.refrigerator.domain.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class GptIngredientDto {
    private String name;
    private int quantity = 1;
    private String unit = "개";
    private String category;
    private String expirationDate; // YYYY-MM-DD 또는 null
}
