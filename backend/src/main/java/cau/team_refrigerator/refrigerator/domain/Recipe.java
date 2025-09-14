package cau.team_refrigerator.refrigerator.domain;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

//

@Entity
@Getter
@NoArgsConstructor
public class Recipe {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String title; // 레시피 제목

    private String ingredients;

    @Column(columnDefinition = "TEXT")
    private String instructions;

    private Integer time;

    private String imageUrl; // 사진 URL

    private String description;

    private boolean isCustom;


    // 사용자가 직접 등록한 레시피의 경우, 작성자와 연결
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "author_id") // uid(X)
    private User author;

    public Recipe(String title, String description, String ingredients, String instructions, int time, String imageUrl, boolean isCustom, User author) {
        this.title = title;
        this.description = description;
        this.ingredients = ingredients;
        this.instructions = instructions;
        this.time = time;
        this.imageUrl = imageUrl;
        this.isCustom = isCustom;
        this.author = author;
    }
}