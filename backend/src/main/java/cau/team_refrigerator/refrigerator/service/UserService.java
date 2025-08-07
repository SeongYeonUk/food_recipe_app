package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.jwt.JwtUtil;
import cau.team_refrigerator.refrigerator.repository.UserRepository;
import cau.team_refrigerator.refrigerator.domain.User;
import cau.team_refrigerator.refrigerator.domain.dto.LoginRequestDto;
import cau.team_refrigerator.refrigerator.domain.dto.SignUpRequestDto;
import jakarta.transaction.Transactional;
import org.springframework.context.annotation.Lazy;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    public UserService(UserRepository userRepository, @Lazy PasswordEncoder passwordEncoder, JwtUtil jwtUtil) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtil = jwtUtil;
    }

    // 회원가입
    @Transactional
    public void signUp(SignUpRequestDto requestDto) {
        // 1. 아이디(uid) 중복 확인
        if (userRepository.findByUid(requestDto.getUid()).isPresent()) {
            throw new IllegalArgumentException("이미 사용중인 아이디입니다.");
        }

        // [변경] 2. 닉네임 중복 확인 로직을 다시 활성화합니다.
        if (userRepository.findByNickname(requestDto.getNickname()).isPresent()) {
            throw new IllegalArgumentException("이미 사용중인 닉네임입니다.");
        }

        String encodedPassword = passwordEncoder.encode(requestDto.getPassword());
        User user = new User(requestDto.getUid(), encodedPassword, requestDto.getNickname());
        userRepository.save(user);
    }

    // 로그인 (수정 없음)
    @Transactional
    public String login(LoginRequestDto requestDto) {
        User user = userRepository.findByUid(requestDto.getUid())
                .orElseThrow(() -> new IllegalArgumentException("가입되지 않은 아이디입니다."));

        if (!passwordEncoder.matches(requestDto.getPassword(), user.getPassword())) {
            throw new IllegalArgumentException("비밀번호가 일치하지 않습니다.");
        }

        return jwtUtil.createToken(user.getUid());
    }
}



