package cau.team_refrigerator.refrigerator.controller;

import cau.team_refrigerator.refrigerator.domain.dto.TokenDto;
import cau.team_refrigerator.refrigerator.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    @PostMapping("/refresh")
    public ResponseEntity<TokenDto.TokenRefreshResponseDto> refreshAccessToken(
            @RequestBody TokenDto.RefreshTokenRequestDto requestDto
    ) {
        String newAccessToken = authService.refreshAccessToken(requestDto.getRefreshToken());
        return ResponseEntity.ok(new TokenDto.TokenRefreshResponseDto(newAccessToken));
    }
}