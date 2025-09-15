package cau.team_refrigerator.refrigerator.domain.dto;

import lombok.Getter;
import lombok.Setter; // [최종 솔루션] Setter를 import 합니다.
import java.util.List;

@Getter
@Setter // [최종 솔루션] Setter 어노테이션을 추가합니다.
public class RecipeCreateRequestDto {

    private String title;
    private String description;
    private List<IngredientDto> ingredients;
    private List<String> instructions;
    private int time;
    private String imageUrl;
    private boolean isCustom;

    // 재료 입력을 위한 중첩 DTO
    @Getter
    @Setter // [최종 솔루션] 중첩 DTO에도 Setter를 추가해줍니다.
    public static class IngredientDto {
        private String name;
        private String amount;
    }
}
