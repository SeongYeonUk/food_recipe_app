package cau.team_refrigerator.refrigerator.repository;


import cau.team_refrigerator.refrigerator.domain.Refrigerator;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RefrigeratorRepository extends JpaRepository<Refrigerator, Long> {
}
