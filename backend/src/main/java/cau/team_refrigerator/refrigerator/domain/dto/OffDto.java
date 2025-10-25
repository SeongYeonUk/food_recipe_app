package cau.team_refrigerator.refrigerator.domain.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class OffDto {
    private String code;
    private String name;
    private String brand;
    private String quantity;
    private String imageUrl;
}
