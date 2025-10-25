package cau.team_refrigerator.refrigerator.repository;

import cau.team_refrigerator.refrigerator.domain.RefreshToken;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface RefreshTokenRepository extends JpaRepository<RefreshToken, String> {
    Optional<RefreshToken> findByTokenValue(String token);
}