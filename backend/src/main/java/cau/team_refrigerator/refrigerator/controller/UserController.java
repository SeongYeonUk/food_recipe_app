package cau.team_refrigerator.refrigerator.controller;

import cau.team_refrigerator.refrigerator.domain.User;
import cau.team_refrigerator.refrigerator.domain.dto.ApiResponseDto;
import cau.team_refrigerator.refrigerator.domain.dto.LoginRequestDto;
import cau.team_refrigerator.refrigerator.domain.dto.SignUpRequestDto;
import cau.team_refrigerator.refrigerator.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import cau.team_refrigerator.refrigerator.domain.dto.LoginResponseDto; // 로그인 응답을 위한 DTO
import java.util.Map; // Map을 사용하기 위해 import 추가
import java.util.HashMap; // HashMap을 사용하기 위해 import 추가
import java.security.Principal; // Spring Security가 인증된 사용자 정보를 주입해주는 객체

@CrossOrigin(origins = "*") // CORS 허용 설정
@RestController
@RequiredArgsConstructor
@RequestMapping("/api") // 기본 경로를 '/api'로 변경하여 유연성 확보
public class UserController {

    private final UserService userService;

    // --- 인증 관련 API (경로: /api/auth/**) ---

    // 회원가입 API
    @PostMapping("/auth/signup")
    public ResponseEntity<ApiResponseDto> signUp(@Valid @RequestBody SignUpRequestDto requestDto) {
        try {
            userService.signUp(requestDto);
            ApiResponseDto response = new ApiResponseDto(HttpStatus.CREATED.value(), "회원가입 성공");
            return new ResponseEntity<>(response, HttpStatus.CREATED);
        } catch (IllegalArgumentException e) {
            ApiResponseDto response = new ApiResponseDto(HttpStatus.CONFLICT.value(), e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.CONFLICT);
        }
    }

    // 로그인 API (***프론트엔드 연동을 위해 응답 방식 수정됨***)
    @PostMapping("/auth/login")
    public ResponseEntity<LoginResponseDto> login(@RequestBody LoginRequestDto requestDto) {
        // 1. UserService로부터 Access 토큰이 담긴 DTO를 받아옴
        LoginResponseDto tokenDto = userService.login(requestDto);

        // 2. 응답 Body에 토큰 DTO를 담아서 클라이언트에게 전달 (헤더 방식보다 Flutter에서 처리하기 용이함)
        return ResponseEntity.ok(tokenDto);
    }

    // 로그아웃 API
    @PostMapping("/auth/logout")
    public ResponseEntity<ApiResponseDto> logout() {
        // stateless한 JWT 특성상, 서버에서 로그아웃은 보통 토큰을 무효화하는 방식으로 구현합니다.
        // (예: Redis에 만료된 토큰을 블랙리스트로 관리)
        // 가장 간단한 방법은 클라이언트 측에서 저장된 토큰을 삭제하는 것입니다.
        // 여기서는 서버에서는 특별한 처리를 하지 않고 성공 응답만 반환합니다.
        ApiResponseDto response = new ApiResponseDto(HttpStatus.OK.value(), "로그아웃 요청 처리됨 (클라이언트에서 토큰 삭제 필요)");
        return ResponseEntity.ok(response);
    }

    // --- 사용자 정보 관련 API (경로: /api/me) ---

    // 내 정보 조회 API (***프론트엔드 연동을 위해 추가***)
    @GetMapping("/me")
    public ResponseEntity<?> getMyProfile(Principal principal) {
        String userId = principal.getName();

        // 바로 이 부분!
        // "userService야, getUserById 메서드를 실행해줘!" 라고 호출하고 있습니다.
        User user = userService.getUserById(userId);

        Map<String, String> responseData = new HashMap<>();
        responseData.put("uid", user.getUid());
        responseData.put("nickname", user.getNickname());

        return ResponseEntity.ok(responseData);
    }

    // 회원 탈퇴 API (***프론트엔드 연동을 위해 경로 및 로직 수정***)
    @DeleteMapping("/me")
    public ResponseEntity<ApiResponseDto> withdraw(Principal principal) {
        String userId = principal.getName();
        userService.withdraw(userId); // 서비스 계층에는 순수한 ID만 전달

        ApiResponseDto response = new ApiResponseDto(HttpStatus.OK.value(), "회원 탈퇴 성공");
        return ResponseEntity.ok(response);
    }
}
