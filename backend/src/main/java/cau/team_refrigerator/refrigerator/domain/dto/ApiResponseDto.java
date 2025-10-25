package cau.team_refrigerator.refrigerator.domain.dto;

import lombok.Getter;

@Getter
public class ApiResponseDto {
    private int status;
    private String message;

    public ApiResponseDto(int status, String message) {
        this.status = status;
        this.message = message;
    }
}