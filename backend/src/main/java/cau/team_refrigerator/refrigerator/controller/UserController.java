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
        userService.signUp(requestDto);
        // 응답 본문에 담을 ApiResponseDto 객체 생성
        ApiResponseDto response = new ApiResponseDto(HttpStatus.CREATED.value(), "회원가입 성공");
        // 201 Created 상태 코드와 함께 응답
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    // 로그인 API
    @PostMapping("/login")
    public ResponseEntity<ApiResponseDto> login(@RequestBody LoginRequestDto requestDto) {
        // 1. 서비스에서 토큰 받아오기
        String token = userService.login(requestDto);
        // 2. 응답 본문에 담을 ApiResponseDto 객체 생성
        ApiResponseDto response = new ApiResponseDto(HttpStatus.OK.value(), "로그인 성공");

        // 3. 최종 응답 생성
        return ResponseEntity.ok() // 상태 코드 200 OK
                .header("Authorization", "Bearer " + token) // 헤더에 토큰 추가
                .body(response); // 본문에는 ApiResponseDto 추가
    }
}