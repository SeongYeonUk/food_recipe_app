package cau.team_refrigerator.refrigerator.domain.dto;

import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class CookingResponseDto {
    private String message;       // TTS로 읽어줄 텍스트
    private String actionType;    // "SPEAK"(말하기), "TIMER_START"(타이머), "FINISH"(요리끝)
    private Integer timerSeconds; // 타이머 설정 시간
}