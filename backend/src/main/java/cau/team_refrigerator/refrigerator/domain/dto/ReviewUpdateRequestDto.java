package cau.team_refrigerator.refrigerator.domain.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class ReviewUpdateRequestDto {
    private String title;
    private String content;
    private String imageUrl;
}