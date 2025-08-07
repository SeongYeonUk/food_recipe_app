package cau.team_refrigerator.refrigerator.jwt;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import org.springframework.stereotype.Component;
import java.security.Key;
import java.util.Base64;
import java.util.Date;

@Component
public class JwtUtil {

    // 1. secretKey를 static final로 선언하여 상수로 만듭니다.
    private static final String SECRET_KEY = "TempSecretKeyForCapstoneDesignProjectLoginTest";

    // 2. key 필드를 final로 선언합니다.
    private final Key key;

    // 3. 토큰 유효시간도 상수로 만듭니다.
    private static final long TOKEN_VALID_TIME = 30 * 60 * 1000L;

    // 생성자에서 final 필드인 key를 초기화합니다.
    public JwtUtil() {
        byte[] keyBytes = Base64.getDecoder().decode(SECRET_KEY);
        this.key = Keys.hmacShaKeyFor(keyBytes);
    }

    // 토큰 생성
    public String createToken(String uid) {
        Date now = new Date();
        return Jwts.builder()
                .setSubject(uid)
                .setIssuedAt(now)
                .setExpiration(new Date(now.getTime() + TOKEN_VALID_TIME))
                .signWith(key, SignatureAlgorithm.HS256)
                .compact();
    }

    // 필요하다면 나중에 토큰 검증 로직을 추가할 수 있습니다.
}
