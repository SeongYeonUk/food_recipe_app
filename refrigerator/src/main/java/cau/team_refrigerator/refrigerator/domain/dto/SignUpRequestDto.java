package cau.team_refrigerator.refrigerator.domain.dto; // 본인의 패키지 경로

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class SignUpRequestDto {
    private String email;
    private String password;
    private String nickname;
}