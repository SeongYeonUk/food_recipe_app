package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.domain.Recipe;
import cau.team_refrigerator.refrigerator.domain.User;
import cau.team_refrigerator.refrigerator.repository.RecipeRepository;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CookingSessionService {

    private final RecipeRepository recipeRepository;

    // 1. 현재 요리 중인 세션 (Key: userId)
    private final Map<Long, SessionInfo> activeSessions = new ConcurrentHashMap<>();

    // 2. 방금 추천받은 레시피 ID 목록 저장 (Key: userId)
    private final Map<Long, List<Long>> lastRecommendedRecipes = new ConcurrentHashMap<>();

    public SessionInfo getActiveSession(Long userId) {
        return activeSessions.get(userId);
    }

    public List<String> getIngredientNamesById(Long recipeId) {
        Recipe recipe = recipeRepository.findByIdIgnoringFilters(recipeId)
                .orElseThrow(() -> new IllegalArgumentException("해당 레시피를 찾을 수 없습니다."));
        return recipe.getRecipeIngredients().stream()
                .map(ri -> ri.getIngredient().getName())
                .distinct()
                .collect(Collectors.toList());
    }

    @Data
    public static class SessionInfo {
        private Long recipeId;
        private String recipeTitle;
        private List<String> steps;
        private int currentStepIndex; // -1: 선택됨(대기중), 0: 1단계, 1: 2단계...
    }

    // [추천 서비스에서 호출] 추천 내역 저장
    public void saveRecommendationHistory(Long userId, List<Long> recipeIds) {
        lastRecommendedRecipes.put(userId, recipeIds);
    }

    // ================================================================================
    // 1. 조리 세션 생성 (선택)
    // ================================================================================

    // [클릭용] ID로 바로 요리 선택 (조리 시작 아님, 대기 상태)
    public String startCookingById(User user, Long recipeId) {
        Recipe recipe = recipeRepository.findByIdIgnoringFilters(recipeId)
                .orElseThrow(() -> new IllegalArgumentException("레시피를 찾을 수 없습니다."));
        return createSession(user, recipe);
    }

    // [음성용] 이름으로 요리 선택 ("오므라이스로 할게") -> 대기 상태 진입
    public String selectRecipeByName(User user, String recipeName) {
        // A. 추천 내역 확인
        List<Long> recommendedIds = lastRecommendedRecipes.get(user.getId());

        if (recommendedIds == null || recommendedIds.isEmpty()) {
            // 추천 내역이 없으면 전체 검색
            Recipe recipe = recipeRepository.findByTitleContaining(recipeName).stream().findFirst()
                    .orElseThrow(() -> new IllegalArgumentException("해당 요리를 찾을 수 없습니다. 먼저 추천을 받아보세요."));
            return createSession(user, recipe);
        }

        // B. 추천 목록 안에서 검색
        Recipe targetRecipe = recipeRepository.findAllById(recommendedIds).stream()
                .filter(r -> r.getTitle().contains(recipeName))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("추천된 목록에 없는 요리입니다. '" + recipeName + "' 대신 추천된 메뉴를 선택해주세요."));

        return createSession(user, targetRecipe);
    }

    // [구버전 호환용] 음성으로 바로 시작 (START 인텐트)
    public String startCookingByName(User user, String recipeName) {
        // selectRecipeByName과 동일하게 세션을 만들고, 바로 1단계(0번)로 설정해도 됨
        // 여기서는 단순히 selectRecipeByName을 호출하여 "선택되었습니다" 메시지를 줌
        // (만약 바로 "1단계는..."을 원한다면 createSession 내부 로직 조정 필요)
        return selectRecipeByName(user, recipeName);
    }

    // [공통] 세션 생성 로직 (Step Index = -1 대기 상태)
    private String createSession(User user, Recipe recipe) {
        SessionInfo session = new SessionInfo();
        session.setRecipeId(recipe.getId());
        session.setRecipeTitle(recipe.getTitle());

        if (recipe.getInstructions() != null && !recipe.getInstructions().isEmpty()) {
            session.setSteps(Arrays.asList(recipe.getInstructions().split("\n")));
        } else {
            session.setSteps(List.of("등록된 조리 순서가 없습니다."));
        }

        session.setCurrentStepIndex(-1); // 👈 핵심: 아직 시작 안 함 (대기 상태)

        // 메모리에 세션 등록
        activeSessions.put(user.getId(), session);

        return recipe.getTitle() + "가 선택되었습니다. 재료를 알려드릴까요, 아니면 조리를 시작할까요?";
    }

    // ================================================================================
    // 2. 정보 조회 (재료, 조리 순서)
    // ================================================================================

    // [음성용] 현재 선택된 세션의 재료 목록 읽어주기
    public String getCurrentRecipeIngredients(User user) {
        SessionInfo session = activeSessions.get(user.getId());
        if (session == null) return "선택된 요리가 없습니다. 먼저 요리를 선택해주세요.";

        // 세션에 저장된 ID로 다시 조회 (재료 정보 Lazy Loading 때문일 수 있음)
        return getRecipeIngredientsById(session.getRecipeId());
    }

    // [음성용] 이름으로 레시피 재료 조회 (추천 단계에서 물어볼 때)
    public String getRecipeIngredients(String recipeName) {
        Recipe recipe = recipeRepository.findByTitleContaining(recipeName).stream().findFirst()
                .orElseThrow(() -> new IllegalArgumentException("해당 요리를 찾을 수 없습니다."));
        return formatIngredientString(recipe);
    }

    // [클릭용] ID로 레시피 재료 조회
    public String getRecipeIngredientsById(Long recipeId) {
        Recipe recipe = recipeRepository.findByIdIgnoringFilters(recipeId)
                .orElseThrow(() -> new IllegalArgumentException("레시피를 찾을 수 없습니다."));
        return formatIngredientString(recipe);
    }

    // [Helper] 재료 목록 포매팅
    private String formatIngredientString(Recipe recipe) {
        String ingredients = recipe.getRecipeIngredients().stream()
                .map(ri -> ri.getIngredient().getName())
                .distinct()
                .collect(Collectors.joining(", "));

        if (ingredients.isEmpty()) return recipe.getTitle() + "의 등록된 재료 정보가 없습니다.";
        return recipe.getTitle() + " 재료는 " + ingredients + "입니다.";
    }

    // ================================================================================
    // 3. 조리 진행 (시작, 다음, 이전)
    // ================================================================================

    // [조리 시작] 대기 상태(-1) -> 1단계(0)로 변경
    public String startCookingSteps(User user) {
        SessionInfo session = activeSessions.get(user.getId());
        if (session == null) return "선택된 요리가 없습니다.";

        session.setCurrentStepIndex(0);
        return "조리를 시작합니다. " + getCurrentStepMessage(session);
    }

    // [다음 단계]
    public String nextStep(User user) {
        SessionInfo session = activeSessions.get(user.getId());
        if (session == null) return "진행 중인 요리가 없습니다. 요리를 먼저 선택해주세요.";

        // 대기 상태(-1)에서 "다음"이라고 하면 조리 시작(0)으로 간주
        if (session.getCurrentStepIndex() == -1) {
            session.setCurrentStepIndex(0);
        } else {
            session.setCurrentStepIndex(session.getCurrentStepIndex() + 1);
        }

        // 마지막 단계 지났으면 종료
        if (session.getCurrentStepIndex() >= session.getSteps().size()) {
            activeSessions.remove(user.getId());
            return "요리가 완성되었습니다! 맛있게 드세요.";
        }
        return getCurrentStepMessage(session);
    }

    // [이전 단계 / 다시 듣기]
    public String repeatStep(User user) {
        SessionInfo session = activeSessions.get(user.getId());
        if (session == null) return "진행 중인 요리가 없습니다.";
        if (session.getCurrentStepIndex() == -1) return "아직 조리가 시작되지 않았습니다. '조리 시작'이라고 말씀해주세요.";

        return getCurrentStepMessage(session);
    }

    // 현재 스텝 메시지 반환
    private String getCurrentStepMessage(SessionInfo session) {
        return "단계 " + (session.getCurrentStepIndex() + 1) + ". " + session.getSteps().get(session.getCurrentStepIndex());
    }

    // 👇 [신규] 조리 중단 (세션 삭제)
    public String stopCooking(User user) {
        if (activeSessions.remove(user.getId()) != null) {
            return "조리를 종료합니다. 수고하셨어요!";
        }
        return "현재 진행 중인 조리가 없습니다.";
    }
}
