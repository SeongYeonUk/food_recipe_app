package cau.team_refrigerator.refrigerator.domain;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import java.util.Collection;
import java.util.Collections;

@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
@Table(name = "users")
public class User implements UserDetails {
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

    // ▼▼▼ UserDetails 인터페이스의 규칙 메서드들을 추가합니다 ▼▼▼

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        // 사용자의 권한을 반환하는 곳입니다. 지금은 간단히 "USER" 권한만 부여합니다.
        return Collections.singletonList(new SimpleGrantedAuthority("ROLE_USER"));
    }

    @Override
    public String getUsername() {
        // Spring Security에서는 username이 ID의 역할을 합니다. 우리는 uid를 ID로 사용합니다.
        return this.uid;
    }

    @Override
    public boolean isAccountNonExpired() {
        // 계정이 만료되지 않았는지 (true: 만료 안됨)
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        // 계정이 잠기지 않았는지 (true: 잠기지 않음)
        return true;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        // 비밀번호가 만료되지 않았는지 (true: 만료 안됨)
        return true;
    }

    @Override
    public boolean isEnabled() {
        // 계정이 활성화되어 있는지 (true: 활성화됨)
        return true;
    }
}