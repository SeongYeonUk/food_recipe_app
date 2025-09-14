package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.domain.*;
import cau.team_refrigerator.refrigerator.domain.dto.MyRecipeResponseDto;
import cau.team_refrigerator.refrigerator.domain.dto.RecipeCreateRequestDto;
import cau.team_refrigerator.refrigerator.domain.dto.RecipeDetailResponseDto;
import cau.team_refrigerator.refrigerator.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true) // 기본적으로는 읽기 전용으로 설정
public class RecipeService {

    private final RecipeRepository recipeRepository;
    private final FavoriteRepository favoriteRepository;
    private final HiddenRecipeRepository hiddenRecipeRepository;
    private final LikeRepository likeRepository;
    private final DislikeRepository dislikeRepository;

    // -------------------나의 레시피 관련 메소드 ------------------------------
    // Create
    @Transactional // 데이터를 저장해야 하므로 readOnly = false로 동작
    public Long createMyRecipe(RecipeCreateRequestDto requestDto, User author) {

        // 1. DTO로 받은 List<IngredientDto>를 String으로 변환
        String ingredientsString = requestDto.getIngredients().stream()
                .map(ing -> ing.getName() + " " + ing.getAmount())
                .collect(Collectors.joining("\n"));

        // 2. DTO로 받은 List<String>을 String으로 변환
        String instructionsString = String.join("\n", requestDto.getInstructions());

        // 3. 변환된 String을 Recipe 생성자에 전달
        Recipe newRecipe = new Recipe(
                requestDto.getTitle(),
                requestDto.getDescription(),
                ingredientsString,       // List 대신 변환된 String 전달
                instructionsString,      // List 대신 변환된 String 전달
                requestDto.getTime(),
                requestDto.getImageUrl(),
                requestDto.isCustom(),
                author
        );

        Recipe savedRecipe = recipeRepository.save(newRecipe);
        Favorite favorite = new Favorite(author, savedRecipe);
        favoriteRepository.save(favorite);
        return savedRecipe.getId();
    }

    // 일괄추가(여러 레시피를 Favorite에 한번에 저장)
    @Transactional
    public void addFavoritesInBulk(List<Long> recipeIds, User currentUser) {
        // 1. ID 목록으로 모든 Recipe 엔티티를 한 번에 조회하여 DB 조회를 최소화합니다.
        List<Recipe> recipes = recipeRepository.findAllById(recipeIds);

        // 2. 각 레시피에 대해 즐겨찾기(Favorite)를 추가합니다.
        for (Recipe recipe : recipes) {
            // 이미 즐겨찾기에 추가되어 있는지 확인하여 중복 저장을 방지합니다.
            boolean isAlreadyFavorite = favoriteRepository.existsByUserAndRecipe(currentUser, recipe);
            if (!isAlreadyFavorite) {
                favoriteRepository.save(new Favorite(currentUser, recipe));
            }
        }
    }

    // Read
    public List<MyRecipeResponseDto> getMyRecipes(User user) {
        List<Favorite> favorites = favoriteRepository.findAllByUser(user);

        return favorites.stream() // favorites 리스트를 스트림으로 변환
                .map(favorite -> new MyRecipeResponseDto(favorite.getRecipe()))
                .collect(Collectors.toList());
    }

    // 레시피 전체 목록 조회
    public List<RecipeDetailResponseDto> getRecipes(User currentUser) {
        // 1. 모든 레시피를 DB에서 조회
        List<Recipe> allRecipes = recipeRepository.findAll();

        // 2. 각 레시피를 DTO로 변환하여 새로운 리스트를 생성
        return allRecipes.stream()
                .map(recipe -> convertToDto(recipe, currentUser)) // 아래 공통 메소드 호출
                .collect(Collectors.toList());
    }

    // Delete
    @Transactional // 데이터를 삭제해야 하므로 readOnly = false로 동작
    public void removeMyRecipe(User user, Long recipeId) {
        favoriteRepository.deleteByUserAndRecipeId(user, recipeId);
    }

    //일괄삭제
    @Transactional
    public void deleteFavoritesInBulk(List<Long> recipeIds, User currentUser) {
        favoriteRepository.deleteAllByUserAndRecipeIds(currentUser, recipeIds);
    }

    // -------------------AI 레시피 관련 메소드 ------------------------------

    // AI 레시피 -> 나만의 레시피
    @Transactional
    public void addFavorite(User user, Long recipeId) {
        // 저장하려는 레시피가 실제로 DB에 있는지 확인
        Recipe recipe = recipeRepository.findById(recipeId)
                .orElseThrow(() -> new IllegalArgumentException("레시피를 찾을 수 없습니다."));

        Favorite favorite = new Favorite(user, recipe);
        favoriteRepository.save(favorite);
    }

    // AI 레시피 조회 (임시 버전)
    public List<MyRecipeResponseDto> getAiRecommendRecipes(User user) {
        List<HiddenRecipe> hiddenRecipes = hiddenRecipeRepository.findAllByUser(user);
        Set<Long> hiddenRecipeIds = hiddenRecipes.stream()
                .map(hidden -> hidden.getRecipe().getId())
                .collect(Collectors.toSet());

        return recipeRepository.findAll().stream()
                .filter(recipe -> !hiddenRecipeIds.contains(recipe.getId())) // 숨긴 ID가 아닌 것만 필터링
                .map(MyRecipeResponseDto::new)
                .collect(Collectors.toList());
    }

    // Delete
    @Transactional
    public void hideAiRecipe(User user, Long recipeId) {
        Recipe recipe = recipeRepository.findById(recipeId)
                .orElseThrow(() -> new IllegalArgumentException("레시피를 찾을 수 없습니다."));

        HiddenRecipe hiddenRecipe = new HiddenRecipe(user, recipe);
        hiddenRecipeRepository.save(hiddenRecipe);
    }

    // 일괄삭제(추천안함)
    @Transactional
    public void hideRecipesInBulk(List<Long> recipeIds, User currentUser) {
        List<Recipe> recipesToHide = recipeRepository.findAllById(recipeIds);

        for (Recipe recipe : recipesToHide) {
            boolean isAlreadyHidden = hiddenRecipeRepository.existsByUserAndRecipe(currentUser, recipe);
            if (!isAlreadyHidden) {
                hiddenRecipeRepository.save(new HiddenRecipe(currentUser, recipe));
            }
        }
    }

    // -------------------레시피 상세 정보 조회 메소드 ------------------------------
    public RecipeDetailResponseDto getRecipeDetails(Long recipeId, User currentUser) {
        Recipe recipe = recipeRepository.findById(recipeId)
                .orElseThrow(() -> new IllegalArgumentException("레시피를 찾을 수 없습니다. ID: " + recipeId));

        return convertToDto(recipe, currentUser); // 공통 메소드 호출
    }

    // Recipe 엔티티를 DTO로 변환하는 공통 로직
    private RecipeDetailResponseDto convertToDto(Recipe recipe, User currentUser)
    {
        boolean isLiked = likeRepository.existsByUserAndRecipe(currentUser, recipe);
        long likeCount = likeRepository.countByRecipe(recipe);
        String userReaction = isLiked ? "liked" : "none";

        List<String> ingredientsList = java.util.Arrays.stream(recipe.getIngredients().split("\n"))
                .filter(line -> !line.trim().isEmpty())
                .collect(Collectors.toList());

        List<String> instructionsList = java.util.Arrays.stream(recipe.getInstructions().split("\n"))
                .filter(line -> !line.trim().isEmpty())
                .collect(Collectors.toList());

        RecipeDetailResponseDto.UserDto userDto = RecipeDetailResponseDto.UserDto.builder()
                .userId(recipe.getAuthor().getId())
                .nickname(recipe.getAuthor().getNickname())
                .build();

        boolean isCustom = recipe.isCustom();

        return RecipeDetailResponseDto.builder()
                .recipeId(recipe.getId())
                .recipeName(recipe.getTitle())
                .ingredients(ingredientsList)
                .instructions(instructionsList)
                .likeCount((int) likeCount)
                .cookingTime(recipe.getTime() + "분")
                .imageUrl(recipe.getImageUrl())
                .isCustom(isCustom)
                .userReaction(userReaction)
                .user(userDto)
                .build();
    }


    @Transactional
    public void updateReaction(Long recipeId, User currentUser, String reaction) {
        Recipe recipe = recipeRepository.findById(recipeId)
                .orElseThrow(() -> new IllegalArgumentException("레시피를 찾을 수 없습니다. ID: " + recipeId));

        // 먼저 기존에 있던 '좋아요 싫어요 기록을 모두 삭합니다.
        likeRepository.deleteByUserAndRecipe(currentUser, recipe);
        dislikeRepository.deleteByUserAndRecipe(currentUser, recipe);

        // 새로운 반응에 따라 데이터를 추가합니다.
        if ("liked".equals(reaction)) {
            // '좋아요'라면 Like 테이블에 새로 추가
            likeRepository.save(new Like(currentUser, recipe));
        } else if ("disliked".equals(reaction)) {
            // '싫어요'라면 Dislike 테이블에 새로 추가
            dislikeRepository.save(new Dislike(currentUser, recipe));
        }
    }

}