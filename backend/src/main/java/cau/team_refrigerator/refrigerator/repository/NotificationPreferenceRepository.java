package cau.team_refrigerator.refrigerator.repository;

import cau.team_refrigerator.refrigerator.domain.NotificationPreference;
import cau.team_refrigerator.refrigerator.domain.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface NotificationPreferenceRepository extends JpaRepository<NotificationPreference, Long> {
    Optional<NotificationPreference> findByUser(User user);
}

