package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.domain.*;
import cau.team_refrigerator.refrigerator.domain.dto.*;
import cau.team_refrigerator.refrigerator.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import cau.team_refrigerator.refrigerator.domain.dto.RecipeBasicResponseDto.BasicRecipeItem;
import com.fasterxml.jackson.databind.ObjectMapper;
import cau.team_refrigerator.refrigerator.client.ApiClient;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import java.io.IOException;

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

    private final ApiClient apiClient; // <--- 4. MockApiClient를 ApiClient로 변경
    private final ObjectMapper objectMapper = new ObjectMapper();

    private final IngredientRepository ingredientRepository;
    private final ItemRepository itemRepository;
    private final RefrigeratorRepository refrigeratorRepository;

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

    // '나만의 레시피' 생성 수정
    @Transactional
    public Long createMyRecipe(RecipeCreateRequestDto requestDto, User author) {
        // String ingredientsString = ... // <-- 이 줄 삭제! (더 이상 필요 없음)
        String instructionsString = String.join("\n", requestDto.getInstructions());

        // 1. Recipe 엔티티 먼저 생성 (아직 재료는 비어있음)
        Recipe newRecipe = Recipe.builder()
                .title(requestDto.getTitle())
                .description(requestDto.getDescription())
                // .ingredients(ingredientsString) // <-- 이 부분 삭제!
                .instructions(instructionsString)
                .time(requestDto.getTime())
                .imageUrl(requestDto.getImageUrl())
                .isCustom(true)
                .author(author)
                .recipeIngredients(new ArrayList<>()) // 빈 리스트로 초기화
                .build();

        // 2. DTO의 재료 목록을 RecipeIngredient 객체로 변환하여 Recipe에 추가
        for (RecipeCreateRequestDto.IngredientDto ingDto : requestDto.getIngredients()) {
            // Ingredient 엔티티 찾기 또는 생성 (배치 작업과 유사한 로직 필요 - IngredientService 등)
            // 여기서는 임시로 이름만 사용
            Ingredient ingredient = findOrCreateIngredient(ingDto.getName()); // <-- 이 메소드 구현 필요

            RecipeIngredient recipeIngredient = RecipeIngredient.builder()
                    .recipe(newRecipe) // recipe 설정
                    .ingredient(ingredient)
                    .amount(ingDto.getAmount())
                    .build();

            // 양방향 관계 설정 (addRecipeIngredient 메소드 사용)
            newRecipe.addRecipeIngredient(recipeIngredient);
        }

        // 3. Recipe 저장 (RecipeIngredient도 cascade 옵션으로 함께 저장됨)
        Recipe savedRecipe = recipeRepository.save(newRecipe);

        // Favorite 저장 로직은 기존과 동일
        Favorite favorite = new Favorite(author, savedRecipe);
        favoriteRepository.save(favorite);
        return savedRecipe.getId();
    }

    // --- Helper Method (실제로는 IngredientService 등으로 분리하는 것이 좋음) ---
    // (IngredientRepository 주입 필요)
    // @Autowired private IngredientRepository ingredientRepository;
    private Ingredient findOrCreateIngredient(String name) {
        String trimmedName = name.trim(); // 앞뒤 공백 제거
        return ingredientRepository.findByName(trimmedName)
                .orElseGet(() -> {
                    System.out.println("새로운 재료 발견 및 저장: " + trimmedName);
                    return ingredientRepository.save(Ingredient.builder().name(trimmedName).build());
                });
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

        List<String> ingredientsList = recipe.getRecipeIngredients().stream()
                .map(ri -> ri.getIngredient().getName() + (ri.getAmount() != null ? " " + ri.getAmount() : "")) // "마늘 10통" 형태로 조합
                .collect(Collectors.toList());

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
                .totalKcal(recipe.getTotalKcal())
                .totalCarbsG(recipe.getTotalCarbsG())
                .totalProteinG(recipe.getTotalProteinG())
                .totalFatG(recipe.getTotalFatG())
                .totalSodiumMg(recipe.getTotalSodiumMg())
                .estimatedMinPriceKrw(recipe.getEstimatedMinPriceKrw())
                .estimatedMaxPriceKrw(recipe.getEstimatedMaxPriceKrw())
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

        List<String> ingredientsList = recipe.getRecipeIngredients().stream()
                .map(ri -> ri.getIngredient().getName() + (ri.getAmount() != null ? " " + ri.getAmount() : ""))
                .collect(Collectors.toList());

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
                .cookingTime(recipe.getTime() != null ? recipe.getTime() + "분" : null)
                .imageUrl(recipe.getImageUrl())
                .isCustom(recipe.isCustom())
                .isFavorite(isFavorite)
                .userReaction(userReaction)
                .user(userDto)
                .totalKcal(recipe.getTotalKcal())
                .totalCarbsG(recipe.getTotalCarbsG())
                .totalProteinG(recipe.getTotalProteinG())
                .totalFatG(recipe.getTotalFatG())
                .totalSodiumMg(recipe.getTotalSodiumMg())
                .estimatedMinPriceKrw(recipe.getEstimatedMinPriceKrw())
                .estimatedMaxPriceKrw(recipe.getEstimatedMaxPriceKrw())
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
    // 1. 기존 searchExternalRecipes(String query) 메소드는 삭제합니다.

    // 2. 아래 3개의 메소드를 클래스에 새로 추가합니다.

    /**
     * [신규] 레시피 기본 정보 검색 (API ...226_1 호출)
     */
    public List<BasicRecipeItem> searchRecipes(String query) {
        // 1. ApiClient로 API 호출 (JSON 문자열 받기)
        String jsonString = apiClient.searchRecipes(query);

        System.out.println("===== API 응답 (JSON 문자열) =====");
        System.out.println(jsonString);
        System.out.println("===============================");

        if (jsonString == null) return Collections.emptyList(); // API 호출 실패

        try {
            // 2. JSON 문자열을 JsonNode(트리 구조)로 파싱
            JsonNode rootNode = objectMapper.readTree(jsonString);

            // 3. "Grid_..._1" (동적 키) 아래의 "row" 배열 찾기
            // fields().next().getValue()가 "Grid_..._1" 노드를 가져옵니다.
            JsonNode gridNode = rootNode.fields().next().getValue();
            JsonNode rowNode = gridNode.get("row"); // "row" 배열

            // 4. "row" 배열을 List<BasicRecipeItem>로 변환
            if (rowNode != null && rowNode.isArray()) {
                return objectMapper.convertValue(
                        rowNode,
                        new TypeReference<List<BasicRecipeItem>>() {}
                );
            }
        } catch (IOException e) { // JsonProcessingException
            System.err.println("JSON 파싱 중 오류가 발생했습니다: " + e.getMessage());
        }

        return Collections.emptyList();
    }

    /**
     * [신규] 레시피 재료 정보 검색 (API ...227_1 호출)
     * (참고: RecipeIngredientResponseDto에 BasicRecipeItem처럼 내부 DTO가 필요할 수 있습니다)
     */
    public List<RecipeIngredientResponseDto> searchIngredients(String recipeId) { // <--- 반환 타입을 실제 DTO의 Item 리스트로 변경하세요
        String jsonString = apiClient.searchIngredients(recipeId);
        if (jsonString == null) return Collections.emptyList();

        try {
            JsonNode rootNode = objectMapper.readTree(jsonString);
            JsonNode gridNode = rootNode.fields().next().getValue();
            JsonNode rowNode = gridNode.get("row");

            if (rowNode != null && rowNode.isArray()) {
                // TODO: 반환 타입 DTO를 List<IngredientItem> 같은 것으로 변경해야 합니다.
                // 우선 RecipeIngredientResponseDto로 가정합니다.
                return objectMapper.convertValue(
                        rowNode,
                        // new TypeReference<List<IngredientItem>>() {} // <--- 이 부분이 실제 DTO에 맞게 수정되어야 합니다.
                        new TypeReference<List<RecipeIngredientResponseDto>>() {}
                );
            }
        } catch (IOException e) {
            System.err.println("JSON 파싱 중 오류가 발생했습니다: " + e.getMessage());
        }
        return Collections.emptyList();
    }

    /**
     * [신규] 레시피 과정 정보 검색 (API ...228_1 호출)
     * (참고: RecipeCourseResponseDto에 BasicRecipeItem처럼 내부 DTO가 필요할 수 있습니다)
     */
    public List<RecipeCourseResponseDto> searchRecipeCourse(String recipeId) { // <--- 반환 타입을 실제 DTO의 Item 리스트로 변경하세요
        String jsonString = apiClient.searchRecipeCourse(recipeId);
        if (jsonString == null) return Collections.emptyList();

        try {
            JsonNode rootNode = objectMapper.readTree(jsonString);
            JsonNode gridNode = rootNode.fields().next().getValue();
            JsonNode rowNode = gridNode.get("row");

            if (rowNode != null && rowNode.isArray()) {
                // TODO: 반환 타입 DTO를 List<CourseItem> 같은 것으로 변경해야 합니다.
                // 우선 RecipeCourseResponseDto로 가정합니다.
                return objectMapper.convertValue(
                        rowNode,
                        // new TypeReference<List<CourseItem>>() {} // <--- 이 부분이 실제 DTO에 맞게 수정되어야 합니다.
                        new TypeReference<List<RecipeCourseResponseDto>>() {}
                );
            }
        } catch (IOException e) {
            System.err.println("JSON 파싱 중 오류가 발생했습니다: " + e.getMessage());
        }
        return Collections.emptyList();
    }

    /**
     * [신규] 사용자의 냉장고 재료 기반으로 AI 레시피 추천
     */
    @Transactional(readOnly = true)
    public List<RecipeDetailResponseDto> recommendRecipes(User currentUser) {
        // 1. 사용자 냉장고 재료 이름 목록 가져오기 (TODO: 실제 구현 필요)
        List<String> userIngredientNames = getUserRefrigeratorIngredients(currentUser);

        if (userIngredientNames.isEmpty()) {
            System.out.println("냉장고에 재료가 없어 추천을 생략합니다.");
            return Collections.emptyList();
        }
        System.out.println("냉장고 재료 기반 추천 시작: " + userIngredientNames);

        Set<String> userIngredientSet = new HashSet<>(userIngredientNames);

        // 2. 재료 이름으로 Ingredient ID 목록 찾기
        List<Long> userIngredientIds = ingredientRepository.findAllByNameIn(userIngredientNames).stream()
                .map(Ingredient::getId)
                .collect(Collectors.toList());

        if (userIngredientIds.isEmpty()) {
            System.out.println("DB에 해당 재료 ID가 없어 추천을 생략합니다.");
            return Collections.emptyList(); // DB에 해당 재료가 하나도 없을 경우
        }
        System.out.println("찾은 재료 ID 목록: " + userIngredientIds);

        // 3. 해당 Ingredient ID 중 하나라도 포함하는 Recipe 찾기
        List<Recipe> recommendedRecipes = recipeRepository.findRecipesWithAnyIngredientIds(userIngredientIds);
        System.out.println("추천 레시피 " + recommendedRecipes.size() + "개 찾음");

        // 4. DTO로 변환하여 반환 (필요한 사용자 활동 정보 미리 로드)
        Set<Long> bookmarkedRecipeIds = bookmarkRepository.findAllByUser(currentUser).stream().map(Bookmark::getRecipeId).collect(Collectors.toSet());
        Set<Long> likedRecipeIds = likeRepository.findAllByUser(currentUser).stream().map(l -> l.getRecipe().getId()).collect(Collectors.toSet());
        Set<Long> dislikedRecipeIds = dislikeRepository.findAllByUser(currentUser).stream().map(d -> d.getRecipe().getId()).collect(Collectors.toSet());
        Set<Long> hiddenRecipeIds = hiddenRecipeRepository.findAllByUser(currentUser).stream().map(h -> h.getRecipe().getId()).collect(Collectors.toSet()); // 숨김 정보 추가

        // 👇👇👇 5. DTO 변환, 매칭 재료 수 계산, 정렬, 상위 10개 선택 👇👇👇
        List<RecipeDetailResponseDto> sortedRecommendations = recommendedRecipes.stream()
                .filter(recipe -> !hiddenRecipeIds.contains(recipe.getId())) // 숨김 레시피 제외
                // --- 각 레시피의 매칭 재료 수 계산 ---
                .map(recipe -> {
                    long matchingIngredientCount = recipe.getRecipeIngredients().stream()
                            .map(ri -> ri.getIngredient().getName()) // 레시피의 재료 이름 가져오기
                            .filter(userIngredientSet::contains)     // 사용자의 재료 목록(Set)에 있는지 확인
                            .count();                               // 겹치는 개수 세기

                    // DTO 변환하면서 매칭 카운트 정보도 임시 저장 (Pair 사용 예시)
                    RecipeDetailResponseDto dto = convertToDtoOptimized(recipe, null, bookmarkedRecipeIds, likedRecipeIds, dislikedRecipeIds);
                    return new AbstractMap.SimpleEntry<>(dto, matchingIngredientCount); // DTO와 매칭 카운트를 쌍으로 만듦
                })
                // --- 매칭 재료 수 많은 순서대로 정렬 (내림차순) ---
                .sorted(Map.Entry.<RecipeDetailResponseDto, Long>comparingByValue().reversed())
                // --- 상위 10개만 선택 ---
                .limit(10)
                // --- 최종 DTO 리스트로 변환 ---
                .map(Map.Entry::getKey)
                .collect(Collectors.toList());

        System.out.println("최종 추천 레시피 " + sortedRecommendations.size() + "개 반환");
        return sortedRecommendations;

    }

    // --- Helper Method for recommendation (최종 구현!) ---
    private List<String> getUserRefrigeratorIngredients(User currentUser) {
        // 1. 사용자의 모든 Refrigerator 엔티티 리스트 찾기
        List<Refrigerator> userRefrigerators = refrigeratorRepository.findByUser(currentUser); // List로 받음

        if (userRefrigerators.isEmpty()) {
            System.out.println("사용자(" + currentUser.getNickname() + ")에게 할당된 냉장고가 없습니다.");
            return Collections.emptyList();
        }
        System.out.println("사용자의 냉장고 " + userRefrigerators.size() + "개 발견.");

        // 2. 모든 냉장고의 모든 Item 목록을 조회하여 재료 이름 수집
        List<String> allIngredientNames = new ArrayList<>();
        for (Refrigerator refrigerator : userRefrigerators) {
            List<Item> items = itemRepository.findAllByRefrigeratorId(refrigerator.getId());
            for (Item item : items) {
                String itemName = item.getName();
                if (itemName != null && !itemName.trim().isEmpty()) {
                    allIngredientNames.add(itemName.trim()); // 공백 제거 후 리스트에 추가
                }
            }
        }

        if (allIngredientNames.isEmpty()) {
            System.out.println("사용자(" + currentUser.getNickname() + ")의 모든 냉장고에 재료 없음.");
            return Collections.emptyList();
        }

        // 3. 중복 제거 후 최종 재료 이름 리스트 반환
        List<String> distinctIngredientNames = allIngredientNames.stream()
                .distinct()
                .collect(Collectors.toList());

        System.out.println("사용자(" + currentUser.getNickname() + ") 냉장고 전체 재료 (중복 제거): " + distinctIngredientNames);
        return distinctIngredientNames;
    }
    // 👇 [수정] timeLimit 파라미터 추가
    // [핵심] 재료 기반 검색 + 랭킹 + 필터링
    public List<RecipeDetailResponseDto> searchByIngredientNames(
            List<String> names,
            String tasteKeyword,
            Integer timeLimit,
            User currentUser
    ) {
        if (names == null || names.isEmpty()) return Collections.emptyList();

        // 1. 재료 이름 정제 및 ID 조회
        List<String> distinctNames = names.stream().map(String::trim).distinct().collect(Collectors.toList());
        Set<String> searchIngredientSet = new HashSet<>(distinctNames);

        List<Ingredient> ingredients = ingredientRepository.findAllByNameIn(distinctNames);
        if (ingredients.isEmpty()) return Collections.emptyList();
        List<Long> ingredientIds = ingredients.stream().map(Ingredient::getId).collect(Collectors.toList());

        // 2. 유저 정보(숨김 목록 등) 로드
        Set<Long> hiddenRecipeIds = hiddenRecipeRepository.findAllByUser(currentUser).stream()
                .map(h -> h.getRecipe().getId()).collect(Collectors.toSet());
        // (bookmark, like 등도 필요 시 로드)

        // 3. 후보군 검색
        List<Recipe> recipes = recipeRepository.findRecipesWithAnyIngredientIds(ingredientIds);

        // 4. 랭킹 & 필터링 로직
        return recipes.stream()
                .filter(r -> !hiddenRecipeIds.contains(r.getId())) // 숨김 제외
                // 시간 필터링
                .filter(r -> timeLimit == null || (r.getTime() != null && r.getTime() <= timeLimit))
                .map(recipe -> {
                    // 점수 계산
                    long matchingCount = recipe.getRecipeIngredients().stream()
                            .map(ri -> ri.getIngredient().getName())
                            .filter(searchIngredientSet::contains)
                            .count();
                    long score = matchingCount * 10;

                    // 맛 가산점
                    if (tasteKeyword != null && (recipe.getTitle().contains(tasteKeyword) ||
                            (recipe.getDescription() != null && recipe.getDescription().contains(tasteKeyword)))) {
                        score += 5;
                    }

                    // DTO 변환 (기존 convertToDtoOptimized 활용)
                    // 편의상 null로 처리된 인자들은 기존 로직에 맞게 채워주세요
                    RecipeDetailResponseDto dto = convertToDtoOptimized(recipe, null, Set.of(), Set.of(), Set.of());
                    return Map.entry(dto, score);
                })
                .sorted(Map.Entry.<RecipeDetailResponseDto, Long>comparingByValue().reversed()) // 점수 내림차순
                .limit(10)
                .map(Map.Entry::getKey)
                .collect(Collectors.toList());
    }
}
