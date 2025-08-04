package cau.team_refrigerator.refrigerator.repository; // 본인의 패_패키지 경로

import cau.team_refrigerator.refrigerator.domain.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {

    // 로그인 시 사용- 아직 구현 X
    Optional<User> findByEmail(String email);
}