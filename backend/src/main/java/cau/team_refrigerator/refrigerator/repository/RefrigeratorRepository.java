package cau.team_refrigerator.refrigerator.repository;


import cau.team_refrigerator.refrigerator.domain.Refrigerator;
import org.springframework.data.jpa.repository.JpaRepository;
import cau.team_refrigerator.refrigerator.domain.User;

import java.util.List;
import java.util.Optional;

public interface RefrigeratorRepository extends JpaRepository<Refrigerator, Long> {
    Optional<Refrigerator> findByIdAndUser(Long id, User user);
    List<Refrigerator> findAllByUser(User user);
    Optional<Refrigerator> findByUser(User user);
}

