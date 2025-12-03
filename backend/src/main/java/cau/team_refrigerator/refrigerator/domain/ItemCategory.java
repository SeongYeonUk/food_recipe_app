package cau.team_refrigerator.refrigerator.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import java.util.stream.Stream;

public enum ItemCategory {
    채소,
    과일,
    유제품,
    육류,
    음료,
    가공식품,
    조미료,
    곡물,
    기타;

    @JsonCreator
    public static ItemCategory fromString(String value) {
        return Stream.of(values())
                .filter(v -> v.name().equalsIgnoreCase(value) || v.name().equals(value))
                .findFirst()
                .orElse(기타);
    }
}
