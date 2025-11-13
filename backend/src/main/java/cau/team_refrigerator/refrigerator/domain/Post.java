package cau.team_refrigerator.refrigerator.domain;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@EntityListeners(AuditingEntityListener.class)
@Entity
public class Post {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "post_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user; // 작성자

    @Column(nullable = false)
    private String title; // "카레라이스"

    @Lob
    @Column(nullable = false)
    private String content; // 레시피 상세 설명

    @Column(nullable = false)
    private String cookTime; // "30분"

    @Lob
    @Column(nullable = false)
    private String ingredients; // "식고가 200g\n감자 2개..."

    private String imageUrl; // 썸네일/상세 이미지 URL

    @CreatedDate
    @Column(updatable = false)
    private LocalDateTime createdAt;

    // --- ⬇️ [핵심 수정] List -> Set, ArrayList -> HashSet으로 변경 ⬇️ ---
    @OneToMany(mappedBy = "post", cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<Like> likes = new HashSet<>(); // 💡 List -> Set 변경

    @OneToMany(mappedBy = "post", cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<Dislike> dislikes = new HashSet<>(); // 💡 List -> Set 변경

    @OneToMany(mappedBy = "post", cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<Review> reviews = new HashSet<>(); // 💡 List -> Set 변경
    // --- ⬆️ [핵심 수정] ⬆️ ---


    // --- 생성자 (Builder) ---
    @Builder
    public Post(User user, String title, String content, String cookTime, String ingredients, String imageUrl) {
        this.user = user;
        this.title = title;
        this.content = content;
        this.cookTime = cookTime;
        this.ingredients = ingredients;
        this.imageUrl = imageUrl;
    }

    // --- 비즈니스 로직: 수정 메서드 ---
    public void update(String title, String content, String cookTime, String ingredients, String imageUrl) {
        this.title = title;
        this.content = content;
        this.cookTime = cookTime;
        this.ingredients = ingredients;
        this.imageUrl = imageUrl;
    }

    // --- 비즈니스 로직: 카운트 메서드 ---

    // '좋아요' 개수
    public int getLikeCount() {
        return (this.likes != null) ? this.likes.size() : 0;
    }

    // '싫어요' 개수
    public int getDislikeCount() {
        return (this.dislikes != null) ? this.dislikes.size() : 0;
    }

    // '후기' 개수
    public int getReviewCount() {
        return (this.reviews != null) ? this.reviews.size() : 0;
    }
}