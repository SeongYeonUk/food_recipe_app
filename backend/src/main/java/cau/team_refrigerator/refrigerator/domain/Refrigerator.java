package cau.team_refrigerator.refrigerator.domain;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
@Table(name = "refrigerators")
public class Refrigerator {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "refrigerator_id") // 컬럼명 지정
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private RefrigeratorType type;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id") // DB에 생성될 외래 키(Foreign Key) 컬럼의 이름
    private User user;

    @Builder
    public Refrigerator(RefrigeratorType type, User user) {
        this.type = type;
        this.user = user;
    }




}
