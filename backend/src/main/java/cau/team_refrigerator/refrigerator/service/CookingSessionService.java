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

@Service
@RequiredArgsConstructor
public class CookingSessionService {

    private final RecipeRepository recipeRepository;

    // 1. 현재 요리 중인 세션 (Key: userId)
    private final Map<Long, SessionInfo> activeSessions = new ConcurrentHashMap<>();

    // 2. 방금 추천받은 레시피 ID 목록 저장 (Key: userId)
    private final Map<Long, List<Long>> lastRecommendedRecipes = new ConcurrentHashMap<>();

    @Data
    public static class SessionInfo {
        private Long recipeId;
        private String recipeTitle;
        private List<String> steps;
        private int currentStepIndex;
    }

    // [추천 서비스에서 호출] 추천 내역 저장
    public void saveRecommendationHistory(Long userId, List<Long> recipeIds) {
        lastRecommendedRecipes.put(userId, recipeIds);
    }

    // 1. [클릭용] ID로 바로 요리 시작 (추천 목록 여부 상관없음)
    public String startCookingById(User user, Long recipeId) {
        Recipe recipe = recipeRepository.findByIdIgnoringFilters(recipeId) // 작성자님 Repo에 있는 메서드 사용
                .orElseThrow(() -> new IllegalArgumentException("레시피를 찾을 수 없습니다."));
        return createSession(user, recipe);
    }

    // 2. [음성용] 이름으로 요리 시작 (⭐️ 추천 목록 내에서만 검색)
    public String startCookingByName(User user, String recipeName) {

        // A. 추천 내역 확인
        List<Long> recommendedIds = lastRecommendedRecipes.get(user.getId());

        if (recommendedIds == null || recommendedIds.isEmpty()) {
            // 추천 내역이 없으면? -> 그냥 전체 DB에서 검색해서 시작 (유연하게 처리)
            // 아까 Repo에 추가한 findByTitleContaining 사용!
            Recipe recipe = recipeRepository.findByTitleContaining(recipeName).stream().findFirst()
                    .orElseThrow(() -> new IllegalArgumentException("해당 요리를 찾을 수 없습니다. 먼저 추천을 받아보세요."));
            return createSession(user, recipe);
        }

        // B. 추천 목록(ID리스트) 안에서 이름 매칭되는 것 찾기
        Recipe targetRecipe = recipeRepository.findAllById(recommendedIds).stream()
                .filter(r -> r.getTitle().contains(recipeName)) // 예: "오므라이스" 포함 확인
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("추천된 목록에 없는 요리입니다. '" + recipeName + "' 대신 추천된 메뉴를 선택해주세요."));

        return createSession(user, targetRecipe);
    }

    // 세션 생성 공통 로직
    private String createSession(User user, Recipe recipe) {
        SessionInfo session = new SessionInfo();
        session.setRecipeId(recipe.getId());
        session.setRecipeTitle(recipe.getTitle());

        // 조리 순서 파싱 (줄바꿈 기준)
        if (recipe.getInstructions() != null && !recipe.getInstructions().isEmpty()) {
            session.setSteps(Arrays.asList(recipe.getInstructions().split("\n")));
        } else {
            session.setSteps(List.of("등록된 조리 순서가 없습니다."));
        }

        session.setCurrentStepIndex(0); // 0번부터 시작

        // 메모리에 세션 등록
        activeSessions.put(user.getId(), session);

        return recipe.getTitle() + " 요리를 시작합니다! 첫 번째 단계입니다. " + getCurrentStepMessage(session);
    }

    // 3. "다음" 단계
    public String nextStep(User user) {
        SessionInfo session = activeSessions.get(user.getId());
        if (session == null) return "진행 중인 요리가 없습니다. 요리를 먼저 시작해주세요.";

        session.setCurrentStepIndex(session.getCurrentStepIndex() + 1);

        // 마지막 단계 지났으면 종료
        if (session.getCurrentStepIndex() >= session.getSteps().size()) {
            activeSessions.remove(user.getId());
            return "요리가 완성되었습니다! 맛있게 드세요.";
        }
        return getCurrentStepMessage(session);
    }

    // 4. "다시" 듣기
    public String repeatStep(User user) {
        SessionInfo session = activeSessions.get(user.getId());
        if (session == null) return "진행 중인 요리가 없습니다.";
        return getCurrentStepMessage(session);
    }

    // 현재 스텝 메시지 만들기
    private String getCurrentStepMessage(SessionInfo session) {
        return "단계 " + (session.getCurrentStepIndex() + 1) + ". " + session.getSteps().get(session.getCurrentStepIndex());
    }
}