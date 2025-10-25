package cau.team_refrigerator.refrigerator.domain;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@NoArgsConstructor
public class RefreshToken {

    @Id // 사용자의 uid를 이 테이블의 기본 키
    private String uid;

    //Refresh Token 값
    private String tokenValue;

    // 생성자
    public RefreshToken(String uid, String tokenValue) {
        this.uid = uid;
        this.tokenValue = tokenValue;
    }
}