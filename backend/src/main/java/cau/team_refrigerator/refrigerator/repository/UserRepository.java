package cau.team_refrigerator.refrigerator.repository;

import cau.team_refrigerator.refrigerator.domain.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByUid(String uid);

    // [추가] 닉네임으로 사용자를 찾는 메소드를 추가합니다.
    Optional<User> findByNickname(String nickname);
}
