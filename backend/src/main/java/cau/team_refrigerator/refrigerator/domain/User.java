package cau.team_refrigerator.refrigerator.domain;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.List;

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

    // ▼▼▼ 여기에 냉장고와의 관계를 추가합니다 ▼▼▼
    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Refrigerator> refrigerators = new ArrayList<>();

    public User(String uid, String password, String nickname) {
        this.uid = uid;
        this.password = password;
        this.nickname = nickname;
    }

    // ▼▼▼ 메인 냉장고를 찾는 편의 메서드를 추가합니다 ▼▼▼
    public Refrigerator getPrimaryRefrigerator() {
        if (refrigerators == null || refrigerators.isEmpty()) {
            throw new IllegalStateException("사용자에게 할당된 냉장고가 없습니다.");
        }

        return refrigerators.stream()
                .filter(Refrigerator::isPrimary)
                .findFirst()
                .orElseThrow(() -> new IllegalStateException("메인 냉장고가 설정되지 않았습니다."));
    }


    // ▼▼▼ UserDetails 인터페이스의 규칙 메서드들은 그대로 유지합니다 ▼▼▼

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return Collections.singletonList(new SimpleGrantedAuthority("ROLE_USER"));
    }

    @Override
    public String getUsername() {
        return this.uid;
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return true;
    }
}