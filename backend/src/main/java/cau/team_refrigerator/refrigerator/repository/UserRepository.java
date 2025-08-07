package cau.team_refrigerator.refrigerator.repository; // 본인의 패_패키지 경로

import cau.team_refrigerator.refrigerator.domain.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

//JpaRepository<User, Long>로 구현 필요X
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByUid(String uid);

     boolean existsByUid(String uid);
     boolean existsByNickname(String nickname);

}