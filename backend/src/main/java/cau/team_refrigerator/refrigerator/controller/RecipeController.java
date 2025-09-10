
package cau.team_refrigerator.refrigerator.controller;

import cau.team_refrigerator.refrigerator.domain.User;
import cau.team_refrigerator.refrigerator.domain.dto.MyRecipeResponseDto;
import cau.team_refrigerator.refrigerator.domain.dto.RecipeCreateRequestDto;
import cau.team_refrigerator.refrigerator.repository.UserRepository;
import cau.team_refrigerator.refrigerator.service.RecipeService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal; // 추가
import org.springframework.security.core.userdetails.UserDetails; // 추가
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/recipes")
public class RecipeController {

    private final RecipeService recipeService;
    private final UserRepository userRepository;

    // 레시피 추가 API
    @PostMapping
    public ResponseEntity<Long> createMyRecipe(
            @RequestBody RecipeCreateRequestDto requestDto,
            @AuthenticationPrincipal UserDetails userDetails // 로그인한 사용자 정보
    ) {
        // UserDetails에서 uid를 가져와 DB에서 전체 유저 정보 조회
        String currentUserId = userDetails.getUsername();
        User currentUser = userRepository.findByUid(currentUserId) // findByUid 메서드가 UserRepository에 필요합니다.
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        Long savedRecipeId = recipeService.createMyRecipe(requestDto, currentUser);

        return ResponseEntity.ok(savedRecipeId);
    }

    // 레시피 조회 API
    @GetMapping("/my")
    public ResponseEntity<List<MyRecipeResponseDto>> getMyRecipes(@AuthenticationPrincipal UserDetails userDetails)
    {
        String currentUserId = userDetails.getUsername();
        User currentUser = userRepository.findByUid(currentUserId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        List<MyRecipeResponseDto> myRecipes = recipeService.getMyRecipes(currentUser);

        return ResponseEntity.ok(myRecipes);
    }



    // 나만의 레시피 삭제 API
    @DeleteMapping("/my/{recipeId}")
    public ResponseEntity<String> removeMyRecipe(
            @PathVariable Long recipeId, // URL 경로에 있는 {recipeId} 값을 받아옴
            @AuthenticationPrincipal UserDetails userDetails
    ) {
        String currentUserId = userDetails.getUsername();
        User currentUser = userRepository.findByUid(currentUserId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        recipeService.removeMyRecipe(currentUser, recipeId);

        return ResponseEntity.ok("레시피가 '나만의 레시피'에서 삭제되었습니다.");
    }

    // '즐겨찾기 추가' API (AI레시피 -> 나만의레시피)
    @PostMapping("/{recipeId}/favorite")
    public ResponseEntity<String> addFavorite(@PathVariable Long recipeId, @AuthenticationPrincipal UserDetails userDetails)
    {
        String currentUserId = userDetails.getUsername();
        User currentUser = userRepository.findByUid(currentUserId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        recipeService.addFavorite(currentUser, recipeId);
        return ResponseEntity.ok("레시피가 '나만의 레시피'에 추가되었습니다.");
    }


    // AI레시피 조회 API
    @GetMapping("/ai-recommend")
    public ResponseEntity<List<MyRecipeResponseDto>> getAiRecommendRecipes(@AuthenticationPrincipal UserDetails userDetails)
    {
        String currentUserId = userDetails.getUsername();
        User currentUser = userRepository.findByUid(currentUserId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        List<MyRecipeResponseDto> recommendRecipes = recipeService.getAiRecommendRecipes(currentUser);
        return ResponseEntity.ok(recommendRecipes);
    }

    // 추천 안함 API(AI레시피 삭제)
    @PostMapping("/ai-recommend/{recipeId}/hide")
    public ResponseEntity<String> hideAiRecipe(@PathVariable Long recipeId, @AuthenticationPrincipal UserDetails userDetails)
    {
        String currentUserId = userDetails.getUsername();
        User currentUser = userRepository.findByUid(currentUserId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        recipeService.hideAiRecipe(currentUser, recipeId);
        return ResponseEntity.ok("해당 레시피가 추천 목록에서 숨김 처리되었습니다.");
    }

}