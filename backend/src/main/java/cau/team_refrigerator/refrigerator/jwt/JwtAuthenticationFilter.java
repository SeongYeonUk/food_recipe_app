// 아래 코드를 복사해서 'jwt' 패키지 안에 있는 JwtAuthenticationFilter.java 파일에 붙여넣으세요.
package cau.team_refrigerator.refrigerator.jwt;

import cau.team_refrigerator.refrigerator.repository.UserRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.User;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collections;

@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;
    private final UserRepository userRepository;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        final String authHeader = request.getHeader("Authorization");

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        final String jwt = authHeader.substring(7);

        // 실제 JwtUtil의 메서드 이름으로 수정됨
        final String userUid = jwtUtil.getUidFromToken(jwt);

        if (userUid != null && SecurityContextHolder.getContext().getAuthentication() == null) {
            userRepository.findByUid(userUid).ifPresent(userEntity -> {

                // 실제 JwtUtil의 메서드 이름과 파라미터에 맞게 수정됨
                if (jwtUtil.validateToken(jwt)) {
                    User userDetails = new User(userEntity.getUid(), userEntity.getPassword(), Collections.emptyList());
                    UsernamePasswordAuthenticationToken authToken = new UsernamePasswordAuthenticationToken(
                            userDetails, null, userDetails.getAuthorities()
                    );
                    SecurityContextHolder.getContext().setAuthentication(authToken);
                }
            });
        }
        filterChain.doFilter(request, response);
    }
}
