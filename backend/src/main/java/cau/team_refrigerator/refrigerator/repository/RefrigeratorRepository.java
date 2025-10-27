package cau.team_refrigerator.refrigerator.repository;


import cau.team_refrigerator.refrigerator.domain.Refrigerator;
import org.springframework.data.jpa.repository.JpaRepository;
import cau.team_refrigerator.refrigerator.domain.User;

import java.util.List;
import java.util.Optional;

public interface RefrigeratorRepository extends JpaRepository<Refrigerator, Long> {
    Optional<Refrigerator> findByIdAndUser(Long id, User user);
    List<Refrigerator> findAllByUser(User user);
    // Optional<Refrigerator> findByUser(User user); // <-- 이 줄을 주석 처리하거나 삭제하고
    List<Refrigerator> findByUser(User user);      // <-- List<Refrigerator> 를 반환하도록 변경
}
