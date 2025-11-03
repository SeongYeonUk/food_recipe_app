package cau.team_refrigerator.refrigerator.domain;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
@Table(name = "home_locations")
public class HomeLocation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(nullable = false)
    private double latitude;

    @Column(nullable = false)
    private double longitude;

    @Column(nullable = false)
    private int radiusMeters = 100; // default 100m

    public HomeLocation(User user, double latitude, double longitude, int radiusMeters) {
        this.user = user;
        this.latitude = latitude;
        this.longitude = longitude;
        if (radiusMeters > 0) this.radiusMeters = radiusMeters;
    }

    public void update(double latitude, double longitude, Integer radiusMeters) {
        this.latitude = latitude;
        this.longitude = longitude;
        if (radiusMeters != null && radiusMeters > 0) this.radiusMeters = radiusMeters;
    }
}

