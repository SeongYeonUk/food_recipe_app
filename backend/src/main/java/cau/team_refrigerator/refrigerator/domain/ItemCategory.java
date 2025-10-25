package cau.team_refrigerator.refrigerator.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import java.util.stream.Stream;

public enum ItemCategory {
    채소,
    과일,
    육류,
    어패류,
    유제품,
    가공식품,
    음료,
    기타;

}
