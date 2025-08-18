// UserService.java 파일의 내용을 아래 코드로 완전히 교체해주세요.

package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.domain.Refrigerator;
import cau.team_refrigerator.refrigerator.domain.RefrigeratorType;
import cau.team_refrigerator.refrigerator.domain.User;
import cau.team_refrigerator.refrigerator.domain.dto.LoginRequestDto;
import cau.team_refrigerator.refrigerator.domain.dto.SignUpRequestDto;
import cau.team_refrigerator.refrigerator.jwt.JwtUtil;
import cau.team_refrigerator.refrigerator.repository.RefrigeratorRepository;
import cau.team_refrigerator.refrigerator.repository.UserRepository;
import org.springframework.context.annotation.Lazy;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import cau.team_refrigerator.refrigerator.domain.dto.LoginResponseDto;
import cau.team_refrigerator.refrigerator.repository.RefreshTokenRepository;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final RefreshTokenRepository refreshTokenRepository;
    private final RefrigeratorRepository refrigeratorRepository;

    public UserService(UserRepository userRepository, RefreshTokenRepository refreshTokenRepository,
                       @Lazy PasswordEncoder passwordEncoder, JwtUtil jwtUtil, RefrigeratorRepository refrigeratorRepository) {
        this.userRepository = userRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtil = jwtUtil;
        this.refrigeratorRepository = refrigeratorRepository;
    }

    @Transactional
    public void signUp(SignUpRequestDto requestDto) {
        if (!requestDto.getPassword().equals(requestDto.getPasswordConfirm())) {
            throw new IllegalArgumentException("비밀번호가 일치하지 않습니다.");
        }
        if (userRepository.findByUid(requestDto.getUid()).isPresent()) {
            throw new IllegalArgumentException("이미 사용중인 아이디입니다.");
        }
        if (userRepository.findByNickname(requestDto.getNickname()).isPresent()) {
            throw new IllegalArgumentException("이미 사용중인 닉네임입니다.");
        }
        String encodedPassword = passwordEncoder.encode(requestDto.getPassword());
        User user = new User(requestDto.getUid(), encodedPassword, requestDto.getNickname());

        User savedUser = userRepository.save(user);

        // allTypes에 모든 종류의 냉장고를 가져옴
        RefrigeratorType[] allTypes = RefrigeratorType.values();

        // 모든 종류의 냉장고 생성/저장
        for (RefrigeratorType type : allTypes) {
            Refrigerator refrigerator = Refrigerator.builder()
                    .type(type)
                    .user(savedUser)
                    .build();
            refrigeratorRepository.save(refrigerator);
        }


    }

    @Transactional
    public LoginResponseDto login(LoginRequestDto requestDto) {
        User user = userRepository.findByUid(requestDto.getUid())
                .orElseThrow(() -> new IllegalArgumentException("가입되지 않은 아이디입니다."));
        if (!passwordEncoder.matches(requestDto.getPassword(), user.getPassword())) {
            throw new IllegalArgumentException("비밀번호가 일치하지 않습니다.");
        }
        String accessToken = jwtUtil.createAccessToken(user.getUid());
        String refreshToken = jwtUtil.createRefreshToken(user.getUid());
        refreshTokenRepository.save(new cau.team_refrigerator.refrigerator.domain.RefreshToken(user.getUid(), refreshToken));
        return new LoginResponseDto(accessToken, refreshToken);
    }

    @Transactional
    public void logout(String userId) {
        refreshTokenRepository.deleteById(userId);
    }

    @Transactional
    public void withdraw(String userId) {
        User user = userRepository.findByUid(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
        refreshTokenRepository.deleteById(userId);
        userRepository.delete(user);
    }

    // ===================================================================
    // ▼▼▼ (핵심 추가) 컨트롤러의 getMyProfile에서 사용할 메서드 ▼▼▼
    // ===================================================================
    @Transactional(readOnly = true)
    public User getUserById(String userId) {
        return userRepository.findByUid(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다: " + userId));
    }
}

