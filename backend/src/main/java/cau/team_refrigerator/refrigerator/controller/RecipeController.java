package cau.team_refrigerator.refrigerator.controller;

import cau.team_refrigerator.refrigerator.domain.User;
import cau.team_refrigerator.refrigerator.domain.dto.*;
import cau.team_refrigerator.refrigerator.repository.UserRepository;
import cau.team_refrigerator.refrigerator.service.RecipeService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import cau.team_refrigerator.refrigerator.domain.dto.RecipeBasicResponseDto;
import cau.team_refrigerator.refrigerator.domain.dto.RecipeIngredientResponseDto;
import cau.team_refrigerator.refrigerator.domain.dto.RecipeCourseResponseDto;

import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/recipes")
public class RecipeController {

    private final RecipeService recipeService;
    private final UserRepository userRepository;

    // --- 레시피 생성 ---
    @PostMapping
    public ResponseEntity<Long> createMyRecipe(
            @RequestBody RecipeCreateRequestDto requestDto,
            @AuthenticationPrincipal UserDetails userDetails
    ) {
        User currentUser = findCurrentUser(userDetails);
        Long savedRecipeId = recipeService.createMyRecipe(requestDto, currentUser);
        return ResponseEntity.ok(savedRecipeId);
    }

    // --- 레시피 조회 ---
    @GetMapping
    public ResponseEntity<List<RecipeDetailResponseDto>> getAllRecipes(
            @AuthenticationPrincipal UserDetails userDetails
    ) {
        User currentUser = findCurrentUser(userDetails);
        List<RecipeDetailResponseDto> recipes = recipeService.getRecipes(currentUser);
        return ResponseEntity.ok(recipes);
    }

    @GetMapping("/{recipeId}")
    public ResponseEntity<RecipeDetailResponseDto> getRecipeDetails(
            @PathVariable Long recipeId,
            @AuthenticationPrincipal UserDetails userDetails
    ) {
        User currentUser = findCurrentUser(userDetails);
        RecipeDetailResponseDto recipeDetails = recipeService.getRecipeDetails(recipeId, currentUser);
        System.out.println(">>> [Debug] JSON으로 변환될 DTO 객체: " + recipeDetails);
        return ResponseEntity.ok(recipeDetails);
    }

    // --- 즐겨찾기 (나만의 레시피) 관리 ---
    @PostMapping("/favorites")
    public ResponseEntity<String> addFavoritesInBulk(
            @RequestBody RecipeIdsRequestDto requestDto,
            @AuthenticationPrincipal UserDetails userDetails
    ) {
        User currentUser = findCurrentUser(userDetails);
        recipeService.addFavoritesInBulk(requestDto.getRecipeIds(), currentUser);
        return ResponseEntity.ok("선택된 레시피들이 '나만의 레시피'에 추가되었습니다.");
    }

    @DeleteMapping("/favorites")
    public ResponseEntity<String> deleteFavoritesInBulk(
            @RequestBody RecipeIdsRequestDto requestDto,
            @AuthenticationPrincipal UserDetails userDetails
    ) {
        User currentUser = findCurrentUser(userDetails);
        recipeService.deleteFavoritesInBulk(requestDto.getRecipeIds(), currentUser);
        return ResponseEntity.ok("선택된 레시피들이 '나만의 레시피'에서 삭제되었습니다.");
    }

    // --- 추천 안함 관리 ---
    @PostMapping("/ai-recommend/hide-bulk")
    public ResponseEntity<String> hideRecipesInBulk(
            @RequestBody RecipeIdsRequestDto requestDto,
            @AuthenticationPrincipal UserDetails userDetails
    ) {
        User currentUser = findCurrentUser(userDetails);
        recipeService.hideRecipesInBulk(requestDto.getRecipeIds(), currentUser);
        return ResponseEntity.ok("선택된 레시피들이 추천 목록에서 숨김 처리되었습니다.");
    }

    // --- 좋아요/싫어요 반응 관리 ---
    @PostMapping("/{recipeId}/reaction")
    public ResponseEntity<String> updateReaction(
            @PathVariable Long recipeId,
            @RequestBody ReactionRequestDto requestDto,
            @AuthenticationPrincipal UserDetails userDetails
    ) {

        User currentUser = findCurrentUser(userDetails);
        recipeService.updateReaction(recipeId, currentUser, requestDto.getReaction());
        return ResponseEntity.ok("반응이 업데이트되었습니다.");
    }

    // --- 중복 코드 제거를 위한 헬퍼 메소드 ---
    private User findCurrentUser(UserDetails userDetails)
    {
        String uid = userDetails.getUsername();
        return userRepository.findByUid(uid)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다. UID: " + uid));
    }

    // 👇👇👇 [신규 추가] AI 레시피 추천 엔드포인트 👇👇👇
    /**
     * 현재 사용자의 냉장고 재료 기반으로 AI 레시피 추천
     * GET /api/recipes/recommendations
     */
    @GetMapping("/recommendations")
    public ResponseEntity<List<RecipeDetailResponseDto>> getRecommendedRecipes(
            @AuthenticationPrincipal UserDetails userDetails // 현재 로그인 사용자 정보 가져오기
    ) {
        // 1. 현재 사용자 찾기
        User currentUser = findCurrentUser(userDetails);

        // 2. RecipeService의 추천 메소드 호출
        List<RecipeDetailResponseDto> recommendations = recipeService.recommendRecipes(currentUser);

        // 3. 추천 결과 반환
        return ResponseEntity.ok(recommendations);
    }
    // --- 외부 API 연동 엔드포인트 ---

    /**
     * 외부 API 레시피 검색 (기본 정보)
     * GET /api/recipes/search?query=김치
     */
    @GetMapping("/search")
    public ResponseEntity<List<RecipeBasicResponseDto.BasicRecipeItem>> searchRecipes(
            @RequestParam String query
    ) {
        // searchExternalRecipes -> searchRecipes로 변경
        List<RecipeBasicResponseDto.BasicRecipeItem> results = recipeService.searchRecipes(query);
        return ResponseEntity.ok(results);
    }

    /**
     * 외부 API 레시피 재료 조회
     * GET /api/recipes/1/ingredients
     */
    @GetMapping("/{recipeId}/ingredients")
    public ResponseEntity<List<RecipeIngredientResponseDto>> getIngredients(
            @PathVariable String recipeId
    ) {
        // (참고: Service에서 반환하는 실제 DTO 타입으로 List<>를 감싸야 합니다)
        List<RecipeIngredientResponseDto> results = recipeService.searchIngredients(recipeId);
        return ResponseEntity.ok(results);
    }

    /**
     * 외부 API 레시피 과정 조회
     * GET /api/recipes/1/course
     */
    @GetMapping("/{recipeId}/course")
    public ResponseEntity<List<RecipeCourseResponseDto>> getRecipeCourse(
            @PathVariable String recipeId
    ) {
        // (참고: Service에서 반환하는 실제 DTO 타입으로 List<>를 감싸야 합니다)
        List<RecipeCourseResponseDto> results = recipeService.searchRecipeCourse(recipeId);
        return ResponseEntity.ok(results);
    }
}
