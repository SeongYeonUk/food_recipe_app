package cau.team_refrigerator.refrigerator.domain;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED) // 외부에서 기본 생성자 호출 제한
@Entity
@Table(name = "users") // 'users' DB 테이블과 매핑
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;


    @Column(nullable = false, unique = true)
    private String uid;

    @Column(nullable = false)
    private String password;

    @Column(nullable = false, unique = true)
    private String nickname;

    public User(String uid, String password, String nickname) {
        this.uid = uid;
        this.password = password;
        this.nickname = nickname;
    }
}
