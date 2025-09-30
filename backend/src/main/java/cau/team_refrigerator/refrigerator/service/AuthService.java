package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.jwt.JwtUtil;
import cau.team_refrigerator.refrigerator.repository.RefreshTokenRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final RefreshTokenRepository refreshTokenRepository;
    private final JwtUtil jwtUtil;

    @Transactional
    public String refreshAccessToken(String refreshToken) {
        if (!jwtUtil.validateToken(refreshToken)) {
            throw new IllegalArgumentException("유효하지 않은 Refresh Token 입니다.");
        }

        refreshTokenRepository.findByTokenValue(refreshToken)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않거나 일치하지 않는 Refresh Token 입니다."));

        String userUid = jwtUtil.getUidFromToken(refreshToken); // getEmailFromToken -> getUidFromToken

        String newAccessToken = jwtUtil.createAccessToken(userUid);

        return newAccessToken;
    }
}