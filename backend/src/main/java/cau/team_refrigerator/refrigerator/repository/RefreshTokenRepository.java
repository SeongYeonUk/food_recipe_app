package cau.team_refrigerator.refrigerator.repository;

import cau.team_refrigerator.refrigerator.domain.RefreshToken;
import org.springframework.data.jpa.repository.JpaRepository;

// JpaRepository를 상속받으면 기본적인 DB 메서드가 자동생성
public interface RefreshTokenRepository extends JpaRepository<RefreshToken, String> {

}