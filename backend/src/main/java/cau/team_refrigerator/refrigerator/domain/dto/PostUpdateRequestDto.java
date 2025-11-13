package cau.team_refrigerator.refrigerator.domain.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor // JSON -> Java 변환 시 필요
public class PostUpdateRequestDto {

    // 클라이언트가 수정할 수 있는 필드들
    private String title;
    private String content;
    private String cookTime;
    private String ingredients;
    private String imageUrl;
}