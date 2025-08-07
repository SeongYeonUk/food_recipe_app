package cau.team_refrigerator.refrigerator.domain;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String uid;

    @Column(nullable = false)
    private String password;

    // [변경] nickname 필드의 @Column 어노테이션에 unique = true 속성을 다시 추가합니다.
    @Column(nullable = false, unique = true)
    private String nickname;

    public User(String uid, String password, String nickname) {
        this.uid = uid;
        this.password = password;
        this.nickname = nickname;
    }
}


