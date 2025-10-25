package cau.team_refrigerator.refrigerator.domain.dto;

import cau.team_refrigerator.refrigerator.domain.Refrigerator;
import cau.team_refrigerator.refrigerator.domain.RefrigeratorType;
import lombok.Getter;

@Getter
public class RefrigeratorResponseDto {
    private Long refrigeratorId;
    private RefrigeratorType type;

    public RefrigeratorResponseDto(Refrigerator refrigerator) {
        this.refrigeratorId = refrigerator.getId();
        this.type = refrigerator.getType();
    }
}