package cau.team_refrigerator.refrigerator.domain.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor // 프레임워크가 JSON을 객체로 변환할 때 필요합니다.
public class ReactionRequestDto {
    private String reaction;
}
