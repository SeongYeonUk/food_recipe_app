package cau.team_refrigerator.refrigerator.controller;

import cau.team_refrigerator.refrigerator.domain.dto.ApiResponseDto;
import cau.team_refrigerator.refrigerator.domain.dto.LoginRequestDto;
import cau.team_refrigerator.refrigerator.domain.dto.SignUpRequestDto;
import cau.team_refrigerator.refrigerator.service.UserService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import cau.team_refrigerator.refrigerator.domain.dto.LoginResponseDto;

@CrossOrigin(origins = "*")
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/auth")
public class UserController {

    private final UserService userService;

    // 회원가입 API
    @PostMapping("/signup")
    public ResponseEntity<ApiResponseDto> signUp(@Valid @RequestBody SignUpRequestDto requestDto) {
        // [수정] try-catch 문으로 서비스 호출 로직을 감쌉니다.
        try {
            userService.signUp(requestDto);

            // 성공 시: 201 Created 상태 코드와 성공 메시지를 담은 응답 반환
            ApiResponseDto response = new ApiResponseDto(HttpStatus.CREATED.value(), "회원가입 성공");
            return new ResponseEntity<>(response, HttpStatus.CREATED);

        } catch (IllegalArgumentException e) {
            // [핵심] UserService에서 던진 예외를 여기서 잡습니다.
            // 실패(중복) 시: 409 Conflict 상태 코드와 예외 메시지를 담은 응답 반환
            ApiResponseDto response = new ApiResponseDto(HttpStatus.CONFLICT.value(), e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.CONFLICT);
        }
    }

    // 로그인 API
    @PostMapping("/login")
    public ResponseEntity<ApiResponseDto> login(@RequestBody LoginRequestDto requestDto) {
        // 1. UserService 로부터 Access/Refresh 토큰이 모두 담긴 DTO를 받아옴
        LoginResponseDto tokenDto = userService.login(requestDto);

        // 2. 성공 메시지를 담은 응답 객체 생성
        ApiResponseDto response = new ApiResponseDto(HttpStatus.OK.value(), "로그인 성공");

        // 3. 헤더에는 AccessToken을 담아서 클라이언트에게 전달
        return ResponseEntity.ok()
                .header("Authorization", "Bearer " + tokenDto.accessToken())
                .body(response);
    }

    @PostMapping("/logout")
    public ResponseEntity<ApiResponseDto> logout(HttpServletRequest request) {
        // 1. 요청 헤더에서 "Authorization" 값을 가져옴
        String accessToken = request.getHeader("Authorization");

        // 2. 서비스를 호출하여 로그아웃 로직을 수행
        userService.logout(accessToken);

        // 3. 성공 응답 반환
        ApiResponseDto response = new ApiResponseDto(HttpStatus.OK.value(), "로그아웃 성공");
        return ResponseEntity.ok(response);
    }

    // 회원탈퇴
    @DeleteMapping("/withdraw")
    public ResponseEntity<ApiResponseDto> withdraw(HttpServletRequest request) {
        String accessToken = request.getHeader("Authorization");

        userService.withdraw(accessToken);

        ApiResponseDto response = new ApiResponseDto(HttpStatus.OK.value(), "회원 탈퇴 성공");
        return ResponseEntity.ok(response);
    }

}
