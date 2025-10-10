package cau.team_refrigerator.refrigerator.domain;

import jakarta.persistence.*;
import lombok.*;

@Getter
@Builder // 클래스 레벨로 이동
@AllArgsConstructor // 추가
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
@Table(name = "refrigerators")
public class Refrigerator {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "refrigerator_id")
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private RefrigeratorType type;

    // ▼▼▼ 여기에 isPrimary 필드를 추가합니다 ▼▼▼
    private boolean isPrimary;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

}