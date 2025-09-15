package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.domain.*;
import cau.team_refrigerator.refrigerator.domain.dto.MyRecipeResponseDto;
import cau.team_refrigerator.refrigerator.domain.dto.RecipeCreateRequestDto;
import cau.team_refrigerator.refrigerator.domain.dto.RecipeDetailResponseDto;
import cau.team_refrigerator.refrigerator.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class RecipeService {

    private final RecipeRepository recipeRepository;
    private final FavoriteRepository favoriteRepository;
    private final HiddenRecipeRepository hiddenRecipeRepository;
    private final LikeRepository likeRepository;
    private final DislikeRepository dislikeRepository;

    @Transactional
    public void deleteFavoritesInBulk(List<Long> recipeIds, User currentUser) {
        List<Recipe> recipesToDelete = recipeRepository.findAllById(recipeIds);

        for (Recipe recipe : recipesToDelete) {
            // "나만의 레시피" 목록에 있는 것은 두 종류가 있음:
            // 1. 내가 직접 만든 레시피 (isCustom = true)
            // 2. 내가 즐겨찾기 한 AI 레시피 (isCustom = false)

            if (recipe.isCustom()) {
                // Case 1: 내가 직접 만든 레시피 -> 레시피 자체를 삭제
                // 작성자 본인인지 확인하는 보안 로직 (선택적이지만 권장)
                if (recipe.getAuthor() != null && recipe.getAuthor().equals(currentUser)) {
                    // Recipe 엔티티에 Cascade 설정이 되어 있으므로, 부모인 Recipe만 삭제하면
                    // JPA가 알아서 모든 자식(Favorite, Like 등)을 먼저 삭제하고 Recipe를 삭제해줍니다.
                    recipeRepository.delete(recipe);
                }
            } else {
                // Case 2: 즐겨찾기 한 AI 레시피 -> Favorite 테이블에서만 삭제 (즐겨찾기 해제)
                favoriteRepository.deleteByUserAndRecipe(currentUser, recipe);
            }
        }
    }

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

    @Transactional
    public void addFavoritesInBulk(List<Long> recipeIds, User currentUser) {
        List<Recipe> recipes = recipeRepository.findAllById(recipeIds);
        for (Recipe recipe : recipes) {
            if (!favoriteRepository.existsByUserAndRecipe(currentUser, recipe)) {
                favoriteRepository.save(new Favorite(currentUser, recipe));
            }
        }
    }

    @Transactional(readOnly = true)
    public List<RecipeDetailResponseDto> getRecipes(User currentUser) {
        Set<Long> hiddenRecipeIds = hiddenRecipeRepository.findAllByUser(currentUser)
                .stream().map(hiddenRecipe -> hiddenRecipe.getRecipe().getId()).collect(Collectors.toSet());
        List<Recipe> allRecipes = recipeRepository.findAll();
        return allRecipes.stream()
                .filter(recipe -> !hiddenRecipeIds.contains(recipe.getId()))
                .map(recipe -> convertToDto(recipe, currentUser)).collect(Collectors.toList());
    }

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
        return convertToDto(recipe, currentUser);
    }

    private RecipeDetailResponseDto convertToDto(Recipe recipe, User currentUser) {
        boolean isLiked = likeRepository.existsByUserAndRecipe(currentUser, recipe);
        long likeCount = likeRepository.countByRecipe(recipe);
        boolean isFavorite = favoriteRepository.existsByUserAndRecipe(currentUser, recipe);
        String userReaction = (isLiked || isFavorite) ? "liked" : "none";
        List<String> ingredientsList = (recipe.getIngredients() != null && !recipe.getIngredients().isEmpty())
                ? java.util.Arrays.stream(recipe.getIngredients().split(",")).map(String::trim).filter(line -> !line.isEmpty()).collect(Collectors.toList())
                : Collections.emptyList();
        List<String> instructionsList = (recipe.getInstructions() != null && !recipe.getInstructions().isEmpty())
                ? java.util.Arrays.stream(recipe.getInstructions().split("\n")).filter(line -> !line.trim().isEmpty()).collect(Collectors.toList())
                : Collections.emptyList();
        RecipeDetailResponseDto.UserDto userDto = (recipe.getAuthor() != null)
                ? RecipeDetailResponseDto.UserDto.builder().userId(recipe.getAuthor().getId()).nickname(recipe.getAuthor().getNickname()).build()
                : null;
        return RecipeDetailResponseDto.builder()
                .recipeId(recipe.getId()).recipeName(recipe.getTitle()).ingredients(ingredientsList)
                .instructions(instructionsList).likeCount((int) likeCount).cookingTime(recipe.getTime() + "분")
                .imageUrl(recipe.getImageUrl()).isCustom(recipe.isCustom()).userReaction(userReaction)
                .user(userDto).build();
    }

    @Transactional
    public void updateReaction(Long recipeId, User currentUser, String reaction) {
        Recipe recipe = recipeRepository.findById(recipeId)
                .orElseThrow(() -> new IllegalArgumentException("레시피를 찾을 수 없습니다. ID: " + recipeId));
        if ("liked".equals(reaction)) {
            if (!favoriteRepository.existsByUserAndRecipe(currentUser, recipe)) {
                favoriteRepository.save(new Favorite(currentUser, recipe));
            }
        } else {
            favoriteRepository.deleteByUserAndRecipe(currentUser, recipe);
        }
    }
}

