package cau.team_refrigerator.refrigerator.domain.dto;

import cau.team_refrigerator.refrigerator.domain.Post;
import cau.team_refrigerator.refrigerator.domain.User;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor // (중요) JSON -> Java 객체 변환 시 필요
public class PostCreateRequestDto {

    private String title;
    private String content;
    private String cookTime;
    private String ingredients;
    private String imageUrl;

    // (Service에서 사용할) DTO를 Entity로 변환하는 메서드
    // 작성자(User) 정보는 Service에서 JWT 토큰을 분석해서 넣어줍니다.
    public Post toEntity(User user) {
        return Post.builder()
                .user(user)
                .title(title)
                .content(content)
                .cookTime(cookTime)
                .ingredients(ingredients)
                .imageUrl(imageUrl)
                .build();
    }
}