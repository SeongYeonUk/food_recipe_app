package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.domain.*;
import cau.team_refrigerator.refrigerator.domain.dto.RecipeCreateRequestDto;
import cau.team_refrigerator.refrigerator.domain.dto.RecipeDetailResponseDto;
import cau.team_refrigerator.refrigerator.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import cau.team_refrigerator.refrigerator.domain.dto.RecipeBasicResponseDto.BasicRecipeItem;
import com.fasterxml.jackson.databind.ObjectMapper;
import cau.team_refrigerator.refrigerator.client.MockApiClient;
import cau.team_refrigerator.refrigerator.domain.dto.RecipeBasicResponseDto;

import java.io.IOException;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class RecipeService {

    private final RecipeRepository recipeRepository;
    private final FavoriteRepository favoriteRepository; // '나만의 레시피'용
    private final BookmarkRepository bookmarkRepository; // '즐겨찾기'용
    private final HiddenRecipeRepository hiddenRecipeRepository;
    private final LikeRepository likeRepository;
    private final DislikeRepository dislikeRepository;

    private final MockApiClient mockApiClient;
    private final ObjectMapper objectMapper = new ObjectMapper();

    // '즐겨찾기 삭제' 로직: BookmarkRepository를 사용합니다.
    @Transactional
    public void deleteFavoritesInBulk(List<Long> recipeIds, User currentUser) {
        System.out.println("!!!!!!!!!! [최신 코드 실행됨] 즐겨찾기 삭제 시도: " + recipeIds + " !!!!!!!!!!");

        List<Recipe> recipesToUnbookmark = recipeRepository.findAllById(recipeIds);
        for (Recipe recipe : recipesToUnbookmark) {
            String recipeType = recipe.isCustom() ? "CUSTOM" : "AI";
            bookmarkRepository.findByUserAndRecipeIdAndRecipeType(currentUser, recipe.getId(), recipeType)
                    .ifPresent(bookmarkRepository::delete);
        }
    }

    // '나만의 레시피' 생성: FavoriteRepository를 사용합니다.
    @Transactional
    public Long createMyRecipe(RecipeCreateRequestDto requestDto, User author) {
        String ingredientsString = requestDto.getIngredients().stream()
                .map(ing -> ing.getName() + " " + ing.getAmount())
                .collect(Collectors.joining("\n"));
        String instructionsString = String.join("\n", requestDto.getInstructions());
        Recipe newRecipe = Recipe.builder()
                .title(requestDto.getTitle()).description(requestDto.getDescription())
                .ingredients(ingredientsString).instructions(instructionsString)
                .time(requestDto.getTime()).imageUrl(requestDto.getImageUrl())
                .isCustom(true).author(author).build();
        Recipe savedRecipe = recipeRepository.save(newRecipe);
        Favorite favorite = new Favorite(author, savedRecipe);
        favoriteRepository.save(favorite);
        return savedRecipe.getId();
    }

    // '즐겨찾기 추가' 로직: BookmarkRepository를 사용합니다.
    @Transactional
    public void addFavoritesInBulk(List<Long> recipeIds, User currentUser) {
        List<Recipe> recipes = recipeRepository.findAllById(recipeIds);
        for (Recipe recipe : recipes) {
            String recipeType = recipe.isCustom() ? "CUSTOM" : "AI";
            if (bookmarkRepository.findByUserAndRecipeIdAndRecipeType(currentUser, recipe.getId(), recipeType).isEmpty()) {
                bookmarkRepository.save(new Bookmark(currentUser, recipe.getId(), recipeType));
            }
        }
    }

    // 전체 레시피 조회 로직: AI 레시피가 누락되었던 버전
    // cau.team_refrigerator.refrigerator.service.RecipeService.java

    // 👇👇👇 1. 이 getRecipes 함수로 교체해주세요. 👇👇👇
    // cau.team_refrigerator.refrigerator.service.RecipeService.java

    @Transactional
    public List<RecipeDetailResponseDto> getRecipes(User currentUser) {
        // 1. 필요한 모든 사용자 활동 정보를 미리 다 가져옵니다.
        Set<Long> hiddenRecipeIds = hiddenRecipeRepository.findAllByUser(currentUser)
                .stream().map(h -> h.getRecipe().getId()).collect(Collectors.toSet());

        Map<Long, Long> favoriteRecipeIdMap = favoriteRepository.findAllByUser(currentUser) // '나만의 레시피'
                .stream()
                .collect(Collectors.toMap(f -> f.getRecipe().getId(), Favorite::getId));

        Set<Long> bookmarkedRecipeIds = bookmarkRepository.findAllByUser(currentUser) // '즐겨찾기'
                .stream().map(Bookmark::getRecipeId).collect(Collectors.toSet());

        Set<Long> likedRecipeIds = likeRepository.findAllByUser(currentUser)
                .stream().map(l -> l.getRecipe().getId()).collect(Collectors.toSet());

        Set<Long> dislikedRecipeIds = dislikeRepository.findAllByUser(currentUser)
                .stream().map(d -> d.getRecipe().getId()).collect(Collectors.toSet());

        // 2. [핵심 수정] DB에 있는 '모든' 레시피를 가져옵니다.
        List<Recipe> allRecipes = recipeRepository.findAll();

        // 3. 모든 레시피를 DTO로 변환합니다.
        return allRecipes.stream()
                // 3-1. 숨김 처리된 레시피는 제외합니다.
                .filter(recipe -> !hiddenRecipeIds.contains(recipe.getId()))
                // 3-2. DTO로 최종 변환합니다.
                .map(recipe -> convertToDtoOptimized(
                        recipe,
                        favoriteRecipeIdMap.get(recipe.getId()), // '나만의 레시피' ID 전달
                        bookmarkedRecipeIds,                     // '즐겨찾기' ID Set 전달
                        likedRecipeIds,
                        dislikedRecipeIds
                ))
                .collect(Collectors.toList());
    }


    // 👇👇👇 2. 이 convertToDtoOptimized 함수로 교체해주세요. 👇👇👇
    private RecipeDetailResponseDto convertToDtoOptimized(
            Recipe recipe,
            Long favoriteId,              // '나만의 레시피' ID
            Set<Long> bookmarkedRecipeIds, // '즐겨찾기' ID Set
            Set<Long> likedRecipeIds,
            Set<Long> dislikedRecipeIds
    ) {
        // isFavorite 여부를 이제 bookmark 기준으로 판단합니다.
        boolean isBookmarked = bookmarkedRecipeIds.contains(recipe.getId());
        boolean isLiked = likedRecipeIds.contains(recipe.getId());
        boolean isDisliked = dislikedRecipeIds.contains(recipe.getId());

        long likeCount = likeRepository.countByRecipe(recipe);

        String userReaction = "none";
        if (isLiked) {
            userReaction = "liked";
        } else if (isDisliked) {
            userReaction = "disliked";
        }

        List<String> ingredientsList = (recipe.getIngredients() != null && !recipe.getIngredients().isEmpty())
                ? java.util.Arrays.asList(recipe.getIngredients().split(","))
                : java.util.Collections.emptyList();

        List<String> instructionsList = (recipe.getInstructions() != null && !recipe.getInstructions().isEmpty())
                ? java.util.Arrays.asList(recipe.getInstructions().split("\n"))
                : java.util.Collections.emptyList();

        RecipeDetailResponseDto.UserDto userDto = (recipe.getAuthor() != null)
                ? new RecipeDetailResponseDto.UserDto(recipe.getAuthor().getId(), recipe.getAuthor().getNickname())
                : null;

        return RecipeDetailResponseDto.builder()
                .favoriteId(favoriteId) // '나만의 레시피' ID는 그대로 전달
                .recipeId(recipe.getId())
                .recipeName(recipe.getTitle())
                .ingredients(ingredientsList)
                .instructions(instructionsList)
                .likeCount((int) likeCount)
                .cookingTime(recipe.getTime() + "분")
                .imageUrl(recipe.getImageUrl())
                .isCustom(recipe.isCustom())
                .isFavorite(isBookmarked) // DTO의 isFavorite 필드에 isBookmarked(즐겨찾기 여부) 값을 전달
                .userReaction(userReaction)
                .user(userDto)
                .build();
    }

    // ... 이하 나머지 함수들은 기존과 동일합니다 ...
    @Transactional
    public void hideRecipesInBulk(List<Long> recipeIds, User currentUser) {
        List<Recipe> recipesToHide = recipeRepository.findAllById(recipeIds);
        for (Recipe recipe : recipesToHide) {
            if (!hiddenRecipeRepository.existsByUserAndRecipe(currentUser, recipe)) {
                hiddenRecipeRepository.save(new HiddenRecipe(currentUser, recipe));
            }
        }
    }

    @Transactional(readOnly = true)
    public RecipeDetailResponseDto getRecipeDetails(Long recipeId, User currentUser) {
        Recipe recipe = recipeRepository.findById(recipeId)
                .orElseThrow(() -> new IllegalArgumentException("레시피를 찾을 수 없습니다. ID: " + recipeId));
        Long favoriteId = favoriteRepository.findByUserAndRecipe(currentUser, recipe)
                .map(Favorite::getId)
                .orElse(null);
        return convertToDto(recipe, currentUser, favoriteId);
    }

    private RecipeDetailResponseDto convertToDto(Recipe recipe, User currentUser, Long favoriteId) {
        boolean isLiked = likeRepository.existsByUserAndRecipe(currentUser, recipe);
        boolean isDisliked = dislikeRepository.existsByUserAndRecipe(currentUser, recipe);
        boolean isFavorite = favoriteId != null;
        long likeCount = likeRepository.countByRecipe(recipe);
        String userReaction = "none";
        if (isLiked) userReaction = "liked";
        else if (isDisliked) userReaction = "disliked";
        List<String> ingredientsList = (recipe.getIngredients() != null && !recipe.getIngredients().isEmpty())
                ? java.util.Arrays.asList(recipe.getIngredients().split(","))
                : Collections.emptyList();
        List<String> instructionsList = (recipe.getInstructions() != null && !recipe.getInstructions().isEmpty())
                ? java.util.Arrays.asList(recipe.getInstructions().split("\n"))
                : Collections.emptyList();
        RecipeDetailResponseDto.UserDto userDto = (recipe.getAuthor() != null)
                ? new RecipeDetailResponseDto.UserDto(recipe.getAuthor().getId(), recipe.getAuthor().getNickname())
                : null;
        return RecipeDetailResponseDto.builder()
                .favoriteId(favoriteId)
                .recipeId(recipe.getId())
                .recipeName(recipe.getTitle())
                .ingredients(ingredientsList)
                .instructions(instructionsList)
                .likeCount((int) likeCount)
                .cookingTime(recipe.getTime() + "분")
                .imageUrl(recipe.getImageUrl())
                .isCustom(recipe.isCustom())
                .isFavorite(isFavorite)
                .userReaction(userReaction)
                .user(userDto)
                .build();
    }

    @Transactional
    public void updateReaction(Long recipeId, User currentUser, String reaction) {
        Recipe recipe = recipeRepository.findByIdIgnoringFilters(recipeId)
                .orElseThrow(() -> new IllegalArgumentException("레시피를 찾을 수 없습니다. ID: " + recipeId));
        if ("liked".equalsIgnoreCase(reaction)) {
            dislikeRepository.deleteByUserAndRecipe(currentUser, recipe);
            Optional<Like> existingLike = likeRepository.findByUserAndRecipe(currentUser, recipe);
            if (existingLike.isPresent()) {
                likeRepository.delete(existingLike.get());
            } else {
                likeRepository.save(new Like(currentUser, recipe));
            }
        } else if ("disliked".equalsIgnoreCase(reaction)) {
            likeRepository.deleteByUserAndRecipe(currentUser, recipe);
            Optional<Dislike> existingDislike = dislikeRepository.findByUserAndRecipe(currentUser, recipe);
            if (existingDislike.isPresent()) {
                dislikeRepository.delete(existingDislike.get());
            } else {
                dislikeRepository.save(new Dislike(currentUser, recipe));
            }
        } else if ("none".equalsIgnoreCase(reaction)) {
            likeRepository.deleteByUserAndRecipe(currentUser, recipe);
            dislikeRepository.deleteByUserAndRecipe(currentUser, recipe);
        }
    }

    public List<BasicRecipeItem> searchExternalRecipes(String query) {
        String jsonResponse = mockApiClient.searchRecipes(query);
        if (jsonResponse == null) {
            return Collections.emptyList();
        }
        try {
            RecipeBasicResponseDto responseDto = objectMapper.readValue(jsonResponse, RecipeBasicResponseDto.class);
            if (responseDto == null || responseDto.getNongsangData() == null || responseDto.getNongsangData().getRow() == null) {
                return Collections.emptyList();
            }
            return responseDto.getNongsangData().getRow().stream()
                    .filter(item -> item.getRecipeNameKo() != null && item.getRecipeNameKo().contains(query))
                    .collect(Collectors.toList());
        } catch (IOException e) {
            System.err.println("JSON 파싱 중 오류가 발생했습니다: " + e.getMessage());
            return Collections.emptyList();
        }
    }
}