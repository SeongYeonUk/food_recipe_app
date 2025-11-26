package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.domain.User;
import cau.team_refrigerator.refrigerator.domain.dto.RecipeBasicResponseDto.BasicRecipeItem;
import cau.team_refrigerator.refrigerator.domain.dto.RecipeDetailResponseDto;
import cau.team_refrigerator.refrigerator.domain.dto.RecipeRecommendationRequestDto;
import cau.team_refrigerator.refrigerator.domain.dto.RecipeRecommendationResponseDto;
import cau.team_refrigerator.refrigerator.repository.ItemRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class RecipeRecommendationService {

    private final RefrigeratorService refrigeratorService;
    private final RecipeService recipeService;
    private final ItemRepository itemRepository;
    // private final CookingSessionService cookingSessionService; // 만약 조리 세션 저장 로직이 필요하다면 주석 해제

    @Transactional(readOnly = true)
    public RecipeRecommendationResponseDto recommendRecipes(RecipeRecommendationRequestDto request, User currentUser) {

        List<String> ingredientsToSearch = new ArrayList<>();
        List<String> matchingSubstitutes = new ArrayList<>(); // 👈 [중요] 변수 선언 및 초기화

        // 1. 유통기한 임박 재료
        if (request.isUseExpiringIngredients()) {
            List<String> expiring = refrigeratorService.getExpiringIngredientNames(currentUser, 2);
            if (!expiring.isEmpty()) {
                ingredientsToSearch.addAll(expiring);
            }
        }

        // 2. 사용자가 말한 필수 재료
        if (request.getMustUseIngredients() != null) {
            ingredientsToSearch.addAll(request.getMustUseIngredients());
        }

        // 3. [수정] 대체 재료 처리 및 기록
        if (request.getSubstituteIngredients() != null && !request.getSubstituteIngredients().isEmpty()) {
            // 로그 확인용
            System.out.println("====== GPT가 제안한 대체 재료 목록: " + request.getSubstituteIngredients());

            // 냉장고 조회
            matchingSubstitutes = itemRepository.findNamesByUserIdAndNamesIn(
                    currentUser.getId(), request.getSubstituteIngredients());

            if (!matchingSubstitutes.isEmpty()) {
                System.out.println("✅ 냉장고 매칭 성공: " + matchingSubstitutes);
                ingredientsToSearch.addAll(matchingSubstitutes);
            }
        }

        // 4. 랭킹 알고리즘 실행 (4개 인자 전달!)
        List<RecipeDetailResponseDto> rankedRecipes = recipeService.searchByIngredientNames(
                ingredientsToSearch,
                request.getTastePreference(),
                request.getTimeLimitMinutes(),
                currentUser
        );

        // 5. 레시피 변환 (DetailDto -> BasicRecipeItem)
        List<BasicRecipeItem> recipeItems = rankedRecipes.stream()
                .map(detail -> {
                    BasicRecipeItem item = new BasicRecipeItem();
                    item.setRecipeId(String.valueOf(detail.getRecipeId()));
                    item.setRecipeNameKo(detail.getRecipeName());
                    item.setSummary(detail.getIngredients().size() + "개 재료 매칭 / " + detail.getCookingTime());
                    item.setCookingTime(detail.getCookingTime());
                    item.setImageUrl(detail.getImageUrl());
                    return item;
                })
                .collect(Collectors.toList());

        // 6. [최종 반환] 종합 결과 DTO 생성
        return RecipeRecommendationResponseDto.builder()
                .suggestedIngredients(request.getSubstituteIngredients()) // GPT 제안 내용
                .matchingIngredients(matchingSubstitutes)                 // 냉장고 매칭 내용
                .recipes(recipeItems)                                     // 레시피 결과
                .build();
    }
}