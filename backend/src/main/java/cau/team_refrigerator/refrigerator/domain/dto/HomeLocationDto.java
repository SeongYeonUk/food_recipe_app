package cau.team_refrigerator.refrigerator.domain.dto;

import cau.team_refrigerator.refrigerator.domain.HomeLocation;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
@AllArgsConstructor
public class HomeLocationDto {
    private double latitude;
    private double longitude;
    private int radiusMeters;

    public static HomeLocationDto from(HomeLocation hl) {
        return new HomeLocationDto(hl.getLatitude(), hl.getLongitude(), hl.getRadiusMeters());
    }
}

