package cau.team_refrigerator.refrigerator.domain.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class BookmarkResponseDto {
    private Long id;
    private String name;
    private String imageUrl; // 필드 이름을 imageUrl로 변경
    private String recipeType;

    public BookmarkResponseDto(Long id, String name, String imageUrl, String recipeType) {
        this.id = id;
        this.name = name;
        this.imageUrl = imageUrl;
        this.recipeType = recipeType;
    }
}