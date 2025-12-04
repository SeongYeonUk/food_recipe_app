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
import java.util.List;
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
    public ResponseEntity<?> recommendRecipe(
            @RequestBody Map<String, String> request,
            Principal principal
    ) {
        System.out.println("📢 [요청 도착] /recommend 엔드포인트");
        User currentUser = findCurrentUser(principal);
        String sttText = request.get("sttText");

        // 1. [안전장치] 여기서도 의도를 먼저 파악합니다!
        String intent = gptApiClient.analyzeIntent(sttText);
        System.out.println("🤖 파악된 의도: " + intent);

        // 2. 만약 질문(대체재료)이라면? -> 검색하지 말고 바로 답변 리턴
        if ("SUBSTITUTE".equals(intent)) {
            String answer = gptApiClient.getSubstituteAnswer(sttText);
            return ResponseEntity.ok(Map.of(
                    "message", answer,
                    "actionType", "SPEAK"
            ));
        }

        // 3. 진짜 추천 요청이라면? -> 기존 로직 실행 (DB 검색)
        RecipeRecommendationRequestDto searchCondition = gptApiClient.getRecipeSearchCondition(sttText);
        return ResponseEntity.ok(recipeRecommendationService.recommendRecipes(searchCondition, currentUser));
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
        System.out.println("📢 [요청 도착] /ask 엔드포인트");
        User currentUser = findCurrentUser(principal);
        String userText = request.get("sttText");

        // 1. 의도 파악
        String intent = gptApiClient.analyzeIntent(userText);
        System.out.println("🗣️ 사용자 질문: " + userText);
        System.out.println("🤖 GPT 판단 의도: [" + intent + "]");

        // 2. 의도에 따른 분기 처리
        if ("CHECK_INVENTORY".equals(intent)) {
            ChatbotInventoryResponseDto response = refrigeratorService.getExpiringItemsForChatbot(currentUser, 3);
            return ResponseEntity.ok(response);

        } else if ("RECOMMEND".equals(intent)) {
            RecipeRecommendationRequestDto condition = gptApiClient.getRecipeSearchCondition(userText);
            return ResponseEntity.ok(recipeRecommendationService.recommendRecipes(condition, currentUser));

        } else if ("SUBSTITUTE".equals(intent)) {
            String answer = gptApiClient.getSubstituteAnswer(userText);
            return ResponseEntity.ok(Map.of(
                    "message", answer,
                    "actionType", "SPEAK"
            ));

            // 👇👇👇 [여기가 핵심!] 조리 관련 명령(COOKING)이면 담당 메서드로 토스! 👇👇👇
        } else if ("COOKING".equals(intent)) {
            // "여기까지 할게", "다음", "오므라이스로 할게" 등은 여기서 처리
            return handleCookingCommand(request, principal);
        }
        // -----------------------------------------------------------------------

        else {
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

        // 1. GPT 의도 분석
        CookingCommandDto command = gptApiClient.parseCookingCommand(sttText);

        // [로그 확인용]
        System.out.println("🗣️ 사용자: " + sttText);
        System.out.println("🤖 의도: " + command.getIntent() + " / 대상: " + command.getRecipeName());

        CookingResponseDto response = new CookingResponseDto();

        switch (command.getIntent()) {
            // 1. 레시피 선택 ("오므라이스로 할게") -> 대기 상태 진입
            case "SELECT":
                String selectMsg = cookingSessionService.selectRecipeByName(currentUser, command.getRecipeName());
                response.setMessage(selectMsg);
                response.setActionType("SPEAK");
                break;

            // 2. 재료 확인 ("재료 알려줘") -> 선택된 요리의 재료 브리핑
            case "INGREDIENTS":
                if (cookingSessionService.getActiveSession(currentUser.getId()) != null) {
                    // 선택된 요리가 있으면 그 재료를 알려줌
                    response.setMessage(cookingSessionService.getCurrentRecipeIngredients(currentUser));
                } else if (command.getRecipeName() != null && !command.getRecipeName().isEmpty()) {
                    // 선택은 안 했지만 요리 이름을 말한 경우 ("오므라이스 재료 알려줘") -> 자동 선택 후 알려줌
                    cookingSessionService.selectRecipeByName(currentUser, command.getRecipeName());
                    String ingMsg = cookingSessionService.getRecipeIngredients(command.getRecipeName());
                    response.setMessage("네, " + command.getRecipeName() + "를 선택했습니다. 재료는 " + ingMsg);
                } else {
                    response.setMessage("어떤 요리의 재료를 알려드릴까요? 요리를 먼저 선택해주세요.");
                }
                response.setActionType("SPEAK");
                break;

            // 3. [중요] 대체 재료 질문 ("쌈장 대체 뭐 있어?") -> GPT 답변
            case "SUBSTITUTE_QUERY":
                String subAnswer = gptApiClient.getSubstituteAnswer(sttText);
                response.setMessage(subAnswer);
                response.setActionType("SPEAK");
                break;

            // 4. 조리 시작 ("요리 시작해") -> 1단계 안내
            case "START_COOKING":
                String startMsg = cookingSessionService.startCookingSteps(currentUser);
                response.setMessage(startMsg);
                response.setActionType("SPEAK");
                break;

            // 5. 다음 단계 ("다음")
            case "NEXT":
                String nextMsg = cookingSessionService.nextStep(currentUser);
                response.setMessage(nextMsg);
                response.setActionType(nextMsg.contains("완성") ? "FINISH" : "SPEAK");
                break;

            // 6. 이전 단계/반복 ("다시 말해줘")
            case "PREVIOUS":
                response.setMessage(cookingSessionService.repeatStep(currentUser));
                response.setActionType("SPEAK");
                break;

            // 7. 타이머 ("3분 타이머")
            case "TIMER":
                int seconds = command.getTimerSeconds();
                String timerLabel = (seconds % 60 == 0) ? (seconds / 60) + "분" : seconds + "초";
                response.setMessage(timerLabel + " 타이머를 설정할게요.");
                response.setActionType("TIMER_START");
                response.setTimerSeconds(seconds);
                break;

            // 8. 종료 ("그만 할게")
            case "STOP":
                String stopMsg = cookingSessionService.stopCooking(currentUser);
                response.setMessage(stopMsg);
                response.setActionType("FINISH");
                break;

            default:
                response.setMessage("죄송해요, 잘 이해하지 못했어요. 다시 말씀해 주세요.");
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
