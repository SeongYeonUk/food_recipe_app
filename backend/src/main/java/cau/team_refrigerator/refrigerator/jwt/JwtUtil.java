package cau.team_refrigerator.refrigerator.jwt;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import java.security.Key;
import java.util.Base64;
import java.util.Date;

@Component
public class JwtUtil {

    //Secret Key를 application.properties 에서 주입받도록 변경
    @Value("${jwt.secret.key}")
    private String secretKey;

    private Key key;
    private static final SignatureAlgorithm signatureAlgorithm = SignatureAlgorithm.HS256;

    // 2. 토큰2개 발급(60분/2주)
    // Access Token- 6000분(임시)
    private static final long ACCESS_TOKEN_VALID_TIME = 600 * 600 * 1000L;
    // Refresh Token- 2주
    private static final long REFRESH_TOKEN_VALID_TIME = 14 * 24 * 60 * 60 * 1000L;

    @PostConstruct // 의존성 주입이 완료된 후 실행됨
    public void init() {
        byte[] keyBytes = Base64.getDecoder().decode(secretKey);
        this.key = Keys.hmacShaKeyFor(keyBytes);
    }

    // Access Token(30분)생성
    public String createAccessToken(String uid) {
        return createToken(uid, ACCESS_TOKEN_VALID_TIME);
    }

    // Refresh Token(2주) 생성
    public String createRefreshToken(String uid) {
        return createToken(uid, REFRESH_TOKEN_VALID_TIME);
    }

    //토큰 생성 로직
    private String createToken(String uid, long validTime) {
        Date now = new Date();
        return Jwts.builder()
                .setSubject(uid)
                .setIssuedAt(now)
                .setExpiration(new Date(now.getTime() + validTime))
                .signWith(key, signatureAlgorithm)
                .compact();
    }

    // 토큰의 유효성 검증
    public boolean validateToken(String token) {
        try {
            Jwts.parserBuilder().setSigningKey(key).build().parseClaimsJws(token);
            return true;
        } catch (Exception e) {
            // 토큰이 유효하지 않을 경우, 실제 운영에서는 로그를 남기는 것이 좋음
            return false;
        }
    }

    // 토큰이 유효하면 uid 추출
    public String getUidFromToken(String token) {
        return Jwts.parserBuilder().setSigningKey(key).build().parseClaimsJws(token).getBody().getSubject();
    }
}