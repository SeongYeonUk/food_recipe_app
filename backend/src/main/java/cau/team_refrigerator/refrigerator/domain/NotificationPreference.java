package cau.team_refrigerator.refrigerator.domain;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
@Table(name = "notification_preferences")
public class NotificationPreference {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    // Daily notification time (local), default 18:00
    @Column(nullable = false)
    private int notifyHour = 18;

    @Column(nullable = false)
    private int notifyMinute = 0;

    @Column(nullable = false)
    private boolean enabled = true;

    // If true, only notify when user is at home (client/geofence gated)
    @Column(nullable = false)
    private boolean homeOnly = false;

    public NotificationPreference(User user) {
        this.user = user;
    }

    public void update(Integer hour, Integer minute, Boolean enabled, Boolean homeOnly) {
        if (hour != null) this.notifyHour = hour;
        if (minute != null) this.notifyMinute = minute;
        if (enabled != null) this.enabled = enabled;
        if (homeOnly != null) this.homeOnly = homeOnly;
    }
}

