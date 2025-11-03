package cau.team_refrigerator.refrigerator.domain;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
@Table(name = "notification_logs")
public class NotificationLog {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private String type; // INGREDIENT / RECIPE

    @Column(nullable = false)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String body;

    private LocalDate scheduledFor; // date considered for daily limit
    private LocalDateTime sentAt;

    @Column(nullable = false)
    private String status; // PENDING / SENT / FAILED

    public NotificationLog(User user, String type, String title, String body, LocalDate scheduledFor, String status) {
        this.user = user;
        this.type = type;
        this.title = title;
        this.body = body;
        this.scheduledFor = scheduledFor;
        this.status = status;
    }

    public void markSent() {
        this.sentAt = LocalDateTime.now();
        this.status = "SENT";
    }
}

