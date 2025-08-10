package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.domain.RefreshToken;
import cau.team_refrigerator.refrigerator.domain.User;
import cau.team_refrigerator.refrigerator.domain.dto.LoginRequestDto;
import cau.team_refrigerator.refrigerator.domain.dto.SignUpRequestDto;
import cau.team_refrigerator.refrigerator.jwt.JwtUtil;
import cau.team_refrigerator.refrigerator.repository.UserRepository;
import jakarta.transaction.Transactional;
import org.springframework.context.annotation.Lazy;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import cau.team_refrigerator.refrigerator.domain.dto.LoginResponseDto;
import cau.team_refrigerator.refrigerator.repository.RefreshTokenRepository;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final RefreshTokenRepository refreshTokenRepository;


    public UserService(UserRepository userRepository, RefreshTokenRepository refreshTokenRepository, @Lazy PasswordEncoder passwordEncoder, JwtUtil jwtUtil) {
        this.userRepository = userRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtil = jwtUtil;
    }

    // 회원가입
    @Transactional
    public void signUp(SignUpRequestDto requestDto) {
        //비밀번호 일치 확인
        if (!requestDto.getPassword().equals(requestDto.getPasswordConfirm())) {
            throw new IllegalArgumentException("비밀번호가 일치하지 않습니다.");
        }

        //아이디 중복 확인
        if (userRepository.findByUid(requestDto.getUid()).isPresent()) {
            throw new IllegalArgumentException("이미 사용중인 아이디입니다.");
        }

        //닉네임 중복 확인
        if (userRepository.findByNickname(requestDto.getNickname()).isPresent()) {
            throw new IllegalArgumentException("이미 사용중인 닉네임입니다.");
        }

        // 비밀번호 암호화 및 사용자 저장
        String encodedPassword = passwordEncoder.encode(requestDto.getPassword());
        User user = new User(requestDto.getUid(), encodedPassword, requestDto.getNickname());
        userRepository.save(user);
    }

    // 로그인
    @Transactional
    public LoginResponseDto login(LoginRequestDto requestDto)
    {
        User user = userRepository.findByUid(requestDto.getUid())
                .orElseThrow(() -> new IllegalArgumentException("가입되지 않은 아이디입니다."));

        if (!passwordEncoder.matches(requestDto.getPassword(), user.getPassword())) {
            throw new IllegalArgumentException("비밀번호가 일치하지 않습니다.");
        }

        String accessToken = jwtUtil.createAccessToken(user.getUid());
        String refreshToken = jwtUtil.createRefreshToken(user.getUid());

        refreshTokenRepository.save(new RefreshToken(user.getUid(), refreshToken));

        return new LoginResponseDto(accessToken, refreshToken);
    }
    @Transactional
    public void logout(String accessToken) {
        // 1. 토큰이 Bearer로 시작하는지 확인 후, 순수 토큰 값만 추출
        if (accessToken != null && accessToken.startsWith("Bearer ")) {
            accessToken = accessToken.substring(7);
        } else {
            // 올바르지 않으면 로그아웃 처리 불가
            throw new IllegalArgumentException("유효하지 않은 토큰 형식입니다.");
        }

        // 2. JwtUtil을 사용해 토큰에서 uid를 추출
        String uid = jwtUtil.getUidFromToken(accessToken);

        // 3. RefreshTokenRepository를 사용해 해당 사용자의 Refresh Token을 DB에서 삭제
        refreshTokenRepository.deleteById(uid);
    }

    @Transactional
    public void withdraw(String accessToken) {
        // 1. 토큰이 Bearer로 시작하는지 확인하고, 순수 토큰 값만 추출
        if (accessToken == null || !accessToken.startsWith("Bearer ")) {
            throw new IllegalArgumentException("유효하지 않은 토큰입니다.");
        }
        String token = accessToken.substring(7);

        // 2. 토큰에서 사용자 uid를 추출
        String uid = jwtUtil.getUidFromToken(token);

        // 3. 사용자 정보를 DB 에서 조회
        User user = userRepository.findByUid(uid)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        // 4. Refresh Token을 먼저 삭제
        refreshTokenRepository.deleteById(uid);

        // 5. 마지막으로 사용자 정보를 삭제
        userRepository.delete(user);
    }

}
