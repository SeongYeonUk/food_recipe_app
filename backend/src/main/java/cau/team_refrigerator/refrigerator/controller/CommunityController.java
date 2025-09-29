package cau.team_refrigerator.refrigerator.controller;

import cau.team_refrigerator.refrigerator.domain.dto.RecipeBasicResponseDto.BasicRecipeItem;
import cau.team_refrigerator.refrigerator.service.RecipeService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController // 이 클래스가 API를 위한 컨트롤러임을 나타냅니다.
@RequiredArgsConstructor
@RequestMapping("/api/community") // 이 컨트롤러의 모든 API는 /api/community 로 시작합니다.
public class CommunityController {

    private final RecipeService recipeService;

    // 다른 커뮤니티 관련 메소드




    /**
     * 커뮤니티 화면에서 외부 레시피를 검색하는 API
     */
    @GetMapping("/search")
    public ResponseEntity<List<BasicRecipeItem>> searchExternalRecipes(
            @RequestParam("query") String query) {

        // 1. RecipeService의 검색 메소드를 호출합니다.
        List<BasicRecipeItem> searchResults = recipeService.searchExternalRecipes(query);

        // 2. 검색 결과를 성공(200 OK) 상태와 함께 반환합니다.
        return ResponseEntity.ok(searchResults);
    }
}