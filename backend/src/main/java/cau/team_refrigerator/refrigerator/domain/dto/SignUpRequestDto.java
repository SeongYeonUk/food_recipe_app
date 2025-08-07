package cau.team_refrigerator.refrigerator.domain.dto; // 본인의 패키지 경로

import jakarta.validation.constraints.Size;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class SignUpRequestDto {

    @NotBlank(message = "아이디를 입력해주세요.")
    private String uid;

    @NotBlank(message = "닉네임을 입력해주세요.")
    @Size(max = 8, message = "닉네임은 8자 이내로 설정해주세요.")
    private String nickname;

    @NotBlank(message = "비밀번호를 입력해주세요.")
    @Size(max = 12, message = "비밀번호는 12자 이내로 설정해주세요.")
    private String password;

    @NotBlank(message = "비밀번호 확인을 입력해주세요.")
    private String passwordConfirm;
}