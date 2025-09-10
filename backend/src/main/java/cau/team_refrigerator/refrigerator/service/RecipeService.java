package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.domain.Favorite;
import cau.team_refrigerator.refrigerator.domain.HiddenRecipe;
import cau.team_refrigerator.refrigerator.domain.Recipe;
import cau.team_refrigerator.refrigerator.domain.User;
import cau.team_refrigerator.refrigerator.domain.dto.MyRecipeResponseDto;
import cau.team_refrigerator.refrigerator.domain.dto.RecipeCreateRequestDto;
import cau.team_refrigerator.refrigerator.repository.FavoriteRepository;
import cau.team_refrigerator.refrigerator.repository.HiddenRecipeRepository;
import cau.team_refrigerator.refrigerator.repository.RecipeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true) // 기본적으로는 읽기 전용으로 설정
public class RecipeService
{

    private final RecipeRepository recipeRepository;
    private final FavoriteRepository favoriteRepository;
    private final HiddenRecipeRepository hiddenRecipeRepository;

    // -------------------나의 레시피 관련 메소드 ------------------------------
    // Create
    @Transactional // 데이터를 저장해야 하므로 readOnly = false로 동작
    public Long createMyRecipe(RecipeCreateRequestDto requestDto, User author)
    {
        Recipe newRecipe = new Recipe(
                requestDto.getTitle(),
                requestDto.getIngredients(),
                requestDto.getInstructions(),
                requestDto.getTime(),
                requestDto.getImageUrl(),
                author
        );

        Recipe savedRecipe = recipeRepository.save(newRecipe);

        Favorite favorite = new Favorite(author, savedRecipe);
        favoriteRepository.save(favorite);

        return savedRecipe.getId();
    }

    // Read
    public List<MyRecipeResponseDto> getMyRecipes(User user)
    {
        List<Favorite> favorites = favoriteRepository.findAllByUser(user);

        return favorites.stream() // favorites 리스트를 스트림으로 변환
                .map(favorite -> new MyRecipeResponseDto(favorite.getRecipe()))
                .collect(Collectors.toList());
    }

    // Delete
    @Transactional // 데이터를 삭제해야 하므로 readOnly = false로 동작
    public void removeMyRecipe(User user, Long recipeId) {
        favoriteRepository.deleteByUserAndRecipeId(user, recipeId);
    }

    // -------------------AI 레시피 관련 메소드 ------------------------------

    // AI 레시피 -> 나만의 레시피
    @Transactional
    public void addFavorite(User user, Long recipeId)
    {
        // 저장하려는 레시피가 실제로 DB에 있는지 확인
        Recipe recipe = recipeRepository.findById(recipeId)
                .orElseThrow(() -> new IllegalArgumentException("레시피를 찾을 수 없습니다."));

        Favorite favorite = new Favorite(user, recipe);
        favoriteRepository.save(favorite);
    }

    // AI 레시피 조회 (임시 버전)
    public List<MyRecipeResponseDto> getAiRecommendRecipes(User user)
    {
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
    public void hideAiRecipe(User user, Long recipeId)
    {
        Recipe recipe = recipeRepository.findById(recipeId)
                .orElseThrow(() -> new IllegalArgumentException("레시피를 찾을 수 없습니다."));

        HiddenRecipe hiddenRecipe = new HiddenRecipe(user, recipe);
        hiddenRecipeRepository.save(hiddenRecipe);
    }




}