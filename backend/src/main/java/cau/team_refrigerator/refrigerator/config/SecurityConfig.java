package cau.team_refrigerator.refrigerator.config;

import cau.team_refrigerator.refrigerator.jwt.JwtAuthenticationFilter; // 추가
import lombok.RequiredArgsConstructor; // 추가
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter; // 추가

@Configuration
@EnableWebSecurity
@RequiredArgsConstructor // final 필드 주입을 위해 추가
public class SecurityConfig {

    // JwtAuthenticationFilter를 주입받도록 필드 추가
    private final JwtAuthenticationFilter jwtAuthenticationFilter;

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http.csrf((csrf) -> csrf.disable());

        http.sessionManagement((sessionManagement) ->
                sessionManagement.sessionCreationPolicy(SessionCreationPolicy.STATELESS)
        );

        http.authorizeHttpRequests((authorize) -> authorize
                .requestMatchers("/api/auth/**", "/error").permitAll()
                .anyRequest().authenticated()
        );

        // *** 이 부분이 가장 중요합니다 ***
        // 우리가 만든 토큰 검사관(jwtAuthenticationFilter)을
        // Spring Security의 기본 경비원 앞에 배치합니다.
        http.addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}