package cau.team_refrigerator.refrigerator.jwt; // 본인의 패키지 경로

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Component;
import java.security.Key;
import java.util.Base64;
import java.util.Date;

@Component
public class JwtUtil {

    // 비밀키(임시)
    private final String secretKey = "TempSecretKeyForCapstoneDesignProjectLoginTest";
    private Key key;

    // 토큰 유효시간-30분
    private final long tokenValidTime = 30 * 60 * 1000L;

    public JwtUtil() {
        byte[] keyBytes = Base64.getDecoder().decode(secretKey);
        this.key = Keys.hmacShaKeyFor(keyBytes);
    }

    // 토큰 생성
    public String createToken(String email) {
        Date now = new Date();
        return Jwts.builder()
                .setSubject(email)
                .setIssuedAt(now)
                .setExpiration(new Date(now.getTime() + tokenValidTime))
                .signWith(key, SignatureAlgorithm.HS256)
                .compact();
    }
}