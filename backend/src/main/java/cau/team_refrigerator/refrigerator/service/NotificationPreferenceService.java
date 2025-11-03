package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.domain.NotificationPreference;
import cau.team_refrigerator.refrigerator.domain.User;
import cau.team_refrigerator.refrigerator.repository.NotificationPreferenceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class NotificationPreferenceService {

    private final NotificationPreferenceRepository preferenceRepository;

    @Transactional
    public NotificationPreference getOrCreate(User user) {
        return preferenceRepository.findByUser(user)
                .orElseGet(() -> preferenceRepository.save(new NotificationPreference(user)));
    }

    @Transactional
    public NotificationPreference update(User user, Integer hour, Integer minute, Boolean enabled, Boolean homeOnly) {
        NotificationPreference pref = getOrCreate(user);
        pref.update(hour, minute, enabled, homeOnly);
        return pref;
    }
}

