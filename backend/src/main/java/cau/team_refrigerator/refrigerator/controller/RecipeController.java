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

import java.util.Collections;
import java.util.List;
import java.util.Map;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/recipes")
public class RecipeController {

    private final RecipeService recipeService;
    private final UserRepository userRepository;

    // --- 1. 레시피 생성 ---
    @PostMapping
    public ResponseEntity<Long> createMyRecipe(
            @RequestBody RecipeCreateRequestDto requestDto,
            @AuthenticationPrincipal UserDetails userDetails
    ) {
        User currentUser = findCurrentUser(userDetails);
        Long savedRecipeId = recipeService.createMyRecipe(requestDto, currentUser);
        return ResponseEntity.ok(savedRecipeId);
    }

    // --- 2. 레시피 조회 (에러 방지를 위해 구체적인 순서대로 정렬) ---
    // [수정됨] 400 에러를 방지하기 위해 GET 매핑 순서를 조정했습니다.

    /**
     * 2-1. "나만의 레시피" 포함 현재 유저의 모든 레시피 조회 (로그인 직후 호출)
     * GET /api/recipes
     * (참고: 원래 호출하려던 /api/recipes/my-recipes 는 이 엔드포인트입니다.)
     */
    @GetMapping
    public ResponseEntity<List<RecipeDetailResponseDto>> getAllRecipes(
            @AuthenticationPrincipal UserDetails userDetails
    ) {
        User currentUser = findCurrentUser(userDetails);
        List<RecipeDetailResponseDto> recipes = recipeService.getRecipes(currentUser);
        return ResponseEntity.ok(recipes);
    }

    /**
     * 2-2. 현재 사용자의 냉장고 재료 기반 AI 레시피 추천
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

    /**
     * 2-3. 외부 API 레시피 검색 (기본 정보)
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
     * 2-4. 외부 API 레시피 재료 조회
     * GET /api/recipes/{recipeId}/ingredients
     * (여기서 {recipeId}는 외부 API의 String ID입니다)
     */
    @GetMapping("/{recipeId}/ingredients")
    public ResponseEntity<List<RecipeIngredientResponseDto>> getIngredients(
            @PathVariable String recipeId
    ) {
        List<RecipeIngredientResponseDto> results = recipeService.searchIngredients(recipeId);
        return ResponseEntity.ok(results);
    }

    /**
     * 2-5. 외부 API 레시피 과정 조회
     * GET /api/recipes/{recipeId}/course
     * (여기서 {recipeId}는 외부 API의 String ID입니다)
     */
    @GetMapping("/{recipeId}/course")
    public ResponseEntity<List<RecipeCourseResponseDto>> getRecipeCourse(
            @PathVariable String recipeId
    ) {
        List<RecipeCourseResponseDto> results = recipeService.searchRecipeCourse(recipeId);
        return ResponseEntity.ok(results);
    }

    /**
     * 2-6. [가장 마지막 순서] 우리 DB 레시피 상세 조회
     * GET /api/recipes/{recipeId}
     * (여기서 {recipeId}는 우리 DB의 Long ID입니다)
     */
    @GetMapping("/{recipeId}")
    public ResponseEntity<RecipeDetailResponseDto> getRecipeDetails(
            @PathVariable Long recipeId, // <-- Long 타입
            @AuthenticationPrincipal UserDetails userDetails
    ) {
        User currentUser = findCurrentUser(userDetails);
        RecipeDetailResponseDto recipeDetails = recipeService.getRecipeDetails(recipeId, currentUser);
        System.out.println(">>> [Debug] JSON으로 변환될 DTO 객체: " + recipeDetails);
        return ResponseEntity.ok(recipeDetails);
    }

    /**
     * 2-7. 선택된 재료 이름 리스트로 레시피 검색
     * POST /api/recipes/search-by-ingredients
     * body: { "names": ["양파", "계란"] }
     */
    @PostMapping("/search-by-ingredients")
    public ResponseEntity<List<RecipeDetailResponseDto>> searchByIngredientNames(
            @RequestBody Map<String, List<String>> body,
            @AuthenticationPrincipal UserDetails userDetails
    ) {
        User currentUser = findCurrentUser(userDetails);
        List<String> names = body.getOrDefault("names", List.of());

        // 👇 [수정] 파라미터 6개를 맞춰줍니다. (맛, 시간, 가격, 칼로리는 null)
        List<RecipeDetailResponseDto> results = recipeService.searchByIngredientNames(
                names,
                null, // tasteKeyword
                null, // timeLimit
                null, // maxPrice (신규)
                null, // maxCalories (신규)
                currentUser
        );
        return ResponseEntity.ok(results);
    }


    // --- 3. 즐겨찾기 (나만의 레시피) 관리 ---
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

    // --- 4. 추천 안함 관리 ---
    @PostMapping("/ai-recommend/hide-bulk")
    public ResponseEntity<String> hideRecipesInBulk(
            @RequestBody RecipeIdsRequestDto requestDto,
            @AuthenticationPrincipal UserDetails userDetails
    ) {
        User currentUser = findCurrentUser(userDetails);
        recipeService.hideRecipesInBulk(requestDto.getRecipeIds(), currentUser);
        return ResponseEntity.ok("선택된 레시피들이 추천 목록에서 숨김 처리되었습니다.");
    }

    // --- 5. 좋아요/싫어요 반응 관리 ---
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

    // --- 6. 중복 코드 제거를 위한 헬퍼 메소드 ---
    private User findCurrentUser(UserDetails userDetails)
    {
        String uid = userDetails.getUsername();
        return userRepository.findByUid(uid)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다. UID: " + uid));
    }
}
