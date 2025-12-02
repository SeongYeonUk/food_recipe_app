package cau.team_refrigerator.refrigerator.controller;

import cau.team_refrigerator.refrigerator.client.GptApiClient;
import cau.team_refrigerator.refrigerator.domain.User;
import cau.team_refrigerator.refrigerator.domain.dto.*;
import cau.team_refrigerator.refrigerator.repository.UserRepository;
import cau.team_refrigerator.refrigerator.service.CookingSessionService;
import cau.team_refrigerator.refrigerator.service.RecipeRecommendationService;
import cau.team_refrigerator.refrigerator.service.RefrigeratorService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.Map;

@RestController
@RequestMapping("/api/chatbot")
@RequiredArgsConstructor
public class ChatbotController {

    private final GptApiClient gptApiClient;
    private final RecipeRecommendationService recipeRecommendationService;
    private final UserRepository userRepository;
    private final CookingSessionService cookingSessionService;
    private final RefrigeratorService refrigeratorService;

    /**
     * 1. [레시피 추천] (음성 -> GPT -> 추천)
     * POST /api/chatbot/recommend
     */
    @PostMapping("/recommend")
    public RecipeRecommendationResponseDto recommendRecipe(
            @RequestBody Map<String, String> request,
            Principal principal
    ) {
        User currentUser = findCurrentUser(principal);
        String sttText = request.get("sttText");

        // GPT에게 검색 조건 추출 요청
        RecipeRecommendationRequestDto searchCondition = gptApiClient.getRecipeSearchCondition(sttText);

        // 추천 서비스 호출 (조건 병합 및 필터링 로직 포함)
        return recipeRecommendationService.recommendRecipes(searchCondition, currentUser);
    }

    /**
     * 2. [통합 대화 API] (냉장고 확인 + 요리 추천 등)
     * POST /api/chatbot/ask
     */
    @PostMapping("/ask")
    public ResponseEntity<?> handleUserRequest(
            @RequestBody Map<String, String> request,
            Principal principal
    ) {
        User currentUser = findCurrentUser(principal);
        String userText = request.get("sttText");

        // 1. 의도 파악
        String intent = gptApiClient.analyzeIntent(userText);

        // 2. 의도에 따른 분기 처리
        if ("CHECK_INVENTORY".equals(intent)) {
            // 냉장고 확인 (3일 이내 임박 재료 기준)
            ChatbotInventoryResponseDto response = refrigeratorService.getExpiringItemsForChatbot(currentUser, 3);
            return ResponseEntity.ok(response);

        } else if ("RECOMMEND".equals(intent)) {
            // 레시피 추천 로직 호출
            RecipeRecommendationRequestDto condition = gptApiClient.getRecipeSearchCondition(userText);
            return ResponseEntity.ok(recipeRecommendationService.recommendRecipes(condition, currentUser));

        } else {
            // 그 외 (요리 모드가 아닌 상태에서의 기타 질문)
            return ResponseEntity.ok(Map.of("message", "죄송해요, 요리 추천이나 냉장고 확인만 도와드릴 수 있어요."));
        }
    }

    /**
     * 3. [조리 중 음성 명령] (시작, 다음, 이전, 타이머, 재료확인)
     * POST /api/chatbot/cooking
     */
    @PostMapping("/cooking")
    public ResponseEntity<CookingResponseDto> handleCookingCommand(
            @RequestBody Map<String, String> request,
            Principal principal
    ) {
        User currentUser = findCurrentUser(principal);
        String sttText = request.get("sttText");

        CookingCommandDto command = gptApiClient.parseCookingCommand(sttText);
        CookingResponseDto response = new CookingResponseDto();

        switch (command.getIntent()) {
            case "SELECT": // "오므라이스로 할게"
                String selectMsg = cookingSessionService.selectRecipeByName(currentUser, command.getRecipeName());
                response.setMessage(selectMsg);
                response.setActionType("SPEAK");
                break;

            case "INGREDIENTS": // "재료 알려줘"
                // (방금 선택한 세션의 재료를 알려줌)
                String ingMsg = cookingSessionService.getCurrentRecipeIngredients(currentUser);
                response.setMessage(ingMsg);
                response.setActionType("SPEAK");
                break;

            case "START_COOKING": // "조리 순서 알려줘", "요리 시작"
                String startMsg = cookingSessionService.startCookingSteps(currentUser);
                response.setMessage(startMsg);
                response.setActionType("SPEAK");
                break;

            case "NEXT": // "다음"
                String nextMsg = cookingSessionService.nextStep(currentUser);
                response.setMessage(nextMsg);
                response.setActionType(nextMsg.contains("완성") ? "FINISH" : "SPEAK");
                break;

            case "PREVIOUS":
                response.setMessage(cookingSessionService.repeatStep(currentUser));
                response.setActionType("SPEAK");
                break;

            case "TIMER":
                int seconds = command.getTimerSeconds();
                response.setMessage(seconds / 60 + "분 타이머를 설정할게요.");
                response.setActionType("TIMER_START");
                response.setTimerSeconds(seconds);
                break;

            case "STOP": // 👇 [신규] "여기까지 할게"
                String stopMsg = cookingSessionService.stopCooking(currentUser);
                response.setMessage(stopMsg);
                response.setActionType("FINISH"); // 앱이 이 타입을 받으면 조리 모드를 끄도록 약속됨
                break;

            default:
                response.setMessage("잘 이해하지 못했어요.");
                response.setActionType("SPEAK");
        }

        return ResponseEntity.ok(response);
    }

    /**
     * 4. [클릭용] 레시피 아이디로 바로 조리 시작
     * POST /api/chatbot/cooking/start/{recipeId}
     */
    @PostMapping("/cooking/start/{recipeId}")
    public ResponseEntity<CookingResponseDto> startCookingByClick(
            @PathVariable Long recipeId,
            Principal principal
    ) {
        User currentUser = findCurrentUser(principal);

        String startMsg = cookingSessionService.startCookingById(currentUser, recipeId);

        CookingResponseDto response = new CookingResponseDto();
        response.setMessage(startMsg);
        response.setActionType("SPEAK");

        return ResponseEntity.ok(response);
    }

    /**
     * 5. [클릭용] 레시피 아이디로 재료 확인 (신규)
     * POST /api/chatbot/cooking/ingredients/{recipeId}
     */
    @PostMapping("/cooking/ingredients/{recipeId}")
    public ResponseEntity<CookingResponseDto> checkIngredientsByClick(
            @PathVariable Long recipeId,
            Principal principal
    ) {
        User currentUser = findCurrentUser(principal);

        // 해당 ID의 레시피 재료 목록 가져오기
        String message = cookingSessionService.getRecipeIngredientsById(recipeId);

        CookingResponseDto response = new CookingResponseDto();
        response.setMessage(message);
        response.setActionType("SPEAK");

        return ResponseEntity.ok(response);
    }

    /**
     * 6. [TTS] 텍스트를 음성(MP3)으로 변환 (GPT 버전)
     * POST /api/chatbot/tts
     */
    @PostMapping("/tts")
    public ResponseEntity<byte[]> generateVoice(@RequestBody Map<String, String> request) {
        String text = request.get("text");

        // GPT TTS 호출
        byte[] audioBytes = gptApiClient.generateTts(text);

        if (audioBytes == null) {
            return ResponseEntity.internalServerError().build();
        }

        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType("audio/mpeg"))
                .body(audioBytes);
    }

    // 유저 조회 헬퍼 메서드
    private User findCurrentUser(Principal principal) {
        if (principal == null) {
            throw new IllegalArgumentException("로그인 정보가 없습니다.");
        }
        String uid = principal.getName();
        return userRepository.findByUid(uid)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 사용자입니다. UID: " + uid));
    }
}