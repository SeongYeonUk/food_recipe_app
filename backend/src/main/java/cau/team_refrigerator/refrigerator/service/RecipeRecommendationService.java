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
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class RecipeRecommendationService {

    private final RefrigeratorService refrigeratorService;
    private final RecipeService recipeService;
    private final ItemRepository itemRepository;
    private final CookingSessionService cookingSessionService;

    // 🧠 [핵심] 사용자별 검색 기록 저장소 (Key: UserId, Value: 마지막 검색 조건)
    private final Map<Long, RecipeRecommendationRequestDto> searchContext = new ConcurrentHashMap<>();

    @Transactional(readOnly = true)
    public RecipeRecommendationResponseDto recommendRecipes(RecipeRecommendationRequestDto request, User currentUser) {

        // 1. 🔄 [기억력 발동] 이전 검색 조건과 합치기
        RecipeRecommendationRequestDto mergedRequest = mergeWithHistory(currentUser.getId(), request);

        System.out.println("🔍 최종 적용된 검색 조건: " + mergedRequest); // 로그 확인용

        List<String> ingredientsToSearch = new ArrayList<>();
        List<String> matchingSubstitutes = new ArrayList<>();

        // 2. 유통기한 임박 재료 (합쳐진 조건 사용)
        if (mergedRequest.isUseExpiringIngredients()) {
            List<String> expiring = refrigeratorService.getExpiringIngredientNames(currentUser, 2);
            if (!expiring.isEmpty()) {
                ingredientsToSearch.addAll(expiring);
            }
        }

        // 3. 필수 재료 (합쳐진 조건 사용)
        if (mergedRequest.getMustUseIngredients() != null) {
            ingredientsToSearch.addAll(mergedRequest.getMustUseIngredients());
        }

        // 4. 대체 재료 (합쳐진 조건 사용)
        if (mergedRequest.getSubstituteIngredients() != null && !mergedRequest.getSubstituteIngredients().isEmpty()) {
            matchingSubstitutes = itemRepository.findNamesByUserIdAndNamesIn(
                    currentUser.getId(), mergedRequest.getSubstituteIngredients());

            if (!matchingSubstitutes.isEmpty()) {
                ingredientsToSearch.addAll(matchingSubstitutes);
            }
        }

        // 5. 랭킹 알고리즘 실행 (시간 제한, 맛 취향 포함)
        List<RecipeDetailResponseDto> rankedRecipes = recipeService.searchByIngredientNames(
                ingredientsToSearch,
                mergedRequest.getTastePreference(),
                mergedRequest.getTimeLimitMinutes(), // 👈 여기서 시간 제한이 들어갑니다!
                mergedRequest.getMaxPrice(),    // 👈 전달
                mergedRequest.getMaxCalories(), // 👈 전달
                currentUser
        );

        // 6. 결과 변환 (DTO)
        List<BasicRecipeItem> recipeItems = rankedRecipes.stream()
                .map(detail -> {
                    BasicRecipeItem item = new BasicRecipeItem();
                    item.setRecipeId(String.valueOf(detail.getRecipeId()));
                    item.setRecipeNameKo(detail.getRecipeName());
                    item.setSummary(detail.getIngredients().size() + "개 재료 매칭 / " + detail.getCookingTime());
                    item.setCookingTime(detail.getCookingTime());
                    item.setImageUrl(detail.getImageUrl());
                    // 👇👇👇 [수정] String.valueOf()를 사용해서 문자열로 변환! 👇👇👇
                    if (detail.getTotalKcal() != null) {
                        item.setCalorie(String.valueOf(detail.getTotalKcal())); // Double -> String 변환
                    }

                    if (detail.getEstimatedMaxPriceKrw() != null) {
                        item.setPriceName(String.valueOf(detail.getEstimatedMaxPriceKrw())); // Double -> String 변환
                    }
                    return item;
                })
                .collect(Collectors.toList());

        // 7. 조리 세션을 위해 추천 목록 저장
        List<Long> recommendedIds = rankedRecipes.stream()
                .map(RecipeDetailResponseDto::getRecipeId)
                .collect(Collectors.toList());
        cookingSessionService.saveRecommendationHistory(currentUser.getId(), recommendedIds);

        // 8. 💾 [기억 저장] 이번에 사용한 조건을 '마지막 기록'으로 저장
        searchContext.put(currentUser.getId(), mergedRequest);

        return RecipeRecommendationResponseDto.builder()
                .suggestedIngredients(mergedRequest.getSubstituteIngredients())
                .matchingIngredients(matchingSubstitutes)
                .recipes(recipeItems)
                .build();
    }

    // 🔄 [조건 합치기 로직 수정]
    private RecipeRecommendationRequestDto mergeWithHistory(Long userId, RecipeRecommendationRequestDto newRequest) {
        RecipeRecommendationRequestDto lastRequest = searchContext.get(userId);

        if (lastRequest == null) return newRequest;

        // 재료가 바뀌면 리셋 (동일)
        if (newRequest.getMustUseIngredients() != null && !newRequest.getMustUseIngredients().isEmpty()) {
            return newRequest;
        }
        if (newRequest.isUseExpiringIngredients()) {
            return newRequest;
        }

        System.out.println("🔗 조건 병합: 재료 유지 + (시간/가격/칼로리) 업데이트");

        // 재료 유지
        newRequest.setMustUseIngredients(lastRequest.getMustUseIngredients());
        newRequest.setUseExpiringIngredients(lastRequest.isUseExpiringIngredients());
        newRequest.setSubstituteIngredients(lastRequest.getSubstituteIngredients());

        // 조건 병합 (새 요청이 null이면 옛날 거 유지)
        if (newRequest.getTastePreference() == null) newRequest.setTastePreference(lastRequest.getTastePreference());
        if (newRequest.getTimeLimitMinutes() == null) newRequest.setTimeLimitMinutes(lastRequest.getTimeLimitMinutes());

        // 👇 [신규] 가격 & 칼로리 병합
        if (newRequest.getMaxPrice() == null) newRequest.setMaxPrice(lastRequest.getMaxPrice());
        if (newRequest.getMaxCalories() == null) newRequest.setMaxCalories(lastRequest.getMaxCalories());

        return newRequest;
    }
}