package cau.team_refrigerator.refrigerator.repository;

import cau.team_refrigerator.refrigerator.domain.HomeLocation;
import cau.team_refrigerator.refrigerator.domain.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface HomeLocationRepository extends JpaRepository<HomeLocation, Long> {
    Optional<HomeLocation> findByUser(User user);
}

