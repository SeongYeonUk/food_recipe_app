package cau.team_refrigerator.refrigerator.repository;

import cau.team_refrigerator.refrigerator.domain.NotificationLog;
import cau.team_refrigerator.refrigerator.domain.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;

public interface NotificationLogRepository extends JpaRepository<NotificationLog, Long> {
    boolean existsByUserAndTypeAndScheduledFor(User user, String type, LocalDate scheduledFor);
    List<NotificationLog> findAllByUserOrderBySentAtDesc(User user);
}

