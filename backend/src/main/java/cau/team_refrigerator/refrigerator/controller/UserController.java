package cau.team_refrigerator.refrigerator.controller;

import cau.team_refrigerator.refrigerator.domain.dto.ApiResponseDto;
import cau.team_refrigerator.refrigerator.domain.dto.LoginRequestDto;
import cau.team_refrigerator.refrigerator.domain.dto.SignUpRequestDto;
import cau.team_refrigerator.refrigerator.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

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

    // 로그인 API (이 코드는 문제가 없으므로 그대로 둡니다)
    @PostMapping("/login")
    public ResponseEntity<ApiResponseDto> login(@RequestBody LoginRequestDto requestDto) {
        String token = userService.login(requestDto);
        ApiResponseDto response = new ApiResponseDto(HttpStatus.OK.value(), "로그인 성공");

        return ResponseEntity.ok()
                .header("Authorization", "Bearer " + token)
                .body(response);
    }
}
