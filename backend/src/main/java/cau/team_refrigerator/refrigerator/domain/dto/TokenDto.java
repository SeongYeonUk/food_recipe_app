package cau.team_refrigerator.refrigerator.domain.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;

public class TokenDto {

    @Getter
    @NoArgsConstructor
    public static class RefreshTokenRequestDto {
        private String refreshToken;
    }

    @Getter
    public static class TokenRefreshResponseDto {
        private final String accessToken;

        public TokenRefreshResponseDto(String accessToken) {
            this.accessToken = accessToken;
        }
    }
}