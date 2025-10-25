package cau.team_refrigerator.refrigerator.domain.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class PopularRecipeDto {
    private Long id;
    private String name;
    private String thumbnail; // 레시피 썸네일 이미지 URL
    private long likeCount;   // '좋아요' 개수

    // 현재 로그인한 유저가 '좋아요'를 눌렀는지 여부
    private boolean isLiked;

    // Repository에서 JPQL로 바로 DTO를 생성하기 위한 생성자
    public PopularRecipeDto(Long id, String name, String thumbnail, long likeCount) {
        this.id = id;
        this.name = name;
        this.thumbnail = thumbnail;
        this.likeCount = likeCount;
    }
}