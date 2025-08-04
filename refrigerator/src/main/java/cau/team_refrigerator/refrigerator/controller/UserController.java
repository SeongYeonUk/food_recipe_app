package cau.team_refrigerator.refrigerator.controller;

import cau.team_refrigerator.refrigerator.service.UserService;
import cau.team_refrigerator.refrigerator.domain.dto.LoginRequestDto;
import cau.team_refrigerator.refrigerator.domain.dto.SignUpRequestDto;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/auth") // '/api/auth'로 시작하는 모든 요청을 이 컨트롤러가 처리
public class UserController {

    private final UserService userService;

    // 회원가입 API
    @PostMapping("/signup")
    public ResponseEntity<String> signUp(@RequestBody SignUpRequestDto requestDto) {
        userService.signUp(requestDto);
        return ResponseEntity.ok("회원가입 성공");
    }

    @PostMapping("/login")
    public ResponseEntity<String> login(@RequestBody LoginRequestDto requestDto) {
        String token = userService.login(requestDto);
        // 클라이언트가 토큰을 받을 수 있도록 헤더에 담아서 보냄
        return ResponseEntity.ok().header("Authorization", "Bearer " + token).body("로그인 성공");
    }
}