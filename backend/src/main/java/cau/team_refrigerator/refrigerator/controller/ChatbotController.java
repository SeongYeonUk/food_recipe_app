package cau.team_refrigerator.refrigerator.controller;

import cau.team_refrigerator.refrigerator.client.GptApiClient;
import cau.team_refrigerator.refrigerator.domain.User;
import cau.team_refrigerator.refrigerator.domain.dto.*;
import cau.team_refrigerator.refrigerator.domain.dto.RecipeBasicResponseDto.BasicRecipeItem;
import cau.team_refrigerator.refrigerator.repository.UserRepository;
import cau.team_refrigerator.refrigerator.service.CookingSessionService;
import cau.team_refrigerator.refrigerator.service.RecipeRecommendationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.MediaType;

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

    // 👇 [수정 1] 이 줄이 빠져서 에러가 났던 겁니다! 추가해주세요.
    private final CookingSessionService cookingSessionService;

    /**
     * 1. 레시피 추천 (음성 -> GPT -> 추천)
     */
    // 👇 반환 타입 변경
    @PostMapping("/recommend")
    public RecipeRecommendationResponseDto recommendRecipe(
            @RequestBody Map<String, String> request,
            Principal principal
    ) {
        User currentUser = findCurrentUser(principal);
        String sttText = request.get("sttText");

        RecipeRecommendationRequestDto searchCondition = gptApiClient.getRecipeSearchCondition(sttText);

        // 서비스 호출 결과 그대로 반환
        return recipeRecommendationService.recommendRecipes(searchCondition, currentUser);
    }

    /**
     * 2. 조리 중 음성 명령 (다음, 타이머, 시작)
     */
    @PostMapping("/cooking")
    public ResponseEntity<CookingResponseDto> handleCookingCommand(
            @RequestBody Map<String, String> request,
            Principal principal // UserDetails 대신 Principal로 통일했습니다 (더 간단함)
    ) {
        User currentUser = findCurrentUser(principal);
        String sttText = request.get("sttText");

        // GPT 의도 파악
        CookingCommandDto command = gptApiClient.parseCookingCommand(sttText);
        CookingResponseDto response = new CookingResponseDto();

        switch (command.getIntent()) {
            case "START":
                // 서비스 메서드명이 startCookingByName 이었는지 확인하세요 (지난번 코드 기준)
                String startMsg = cookingSessionService.startCookingByName(currentUser, command.getRecipeName());
                response.setMessage(startMsg);
                response.setActionType("SPEAK");
                break;

            case "NEXT":
                String nextMsg = cookingSessionService.nextStep(currentUser);
                response.setMessage(nextMsg);
                // "완성"이라는 단어가 있으면 요리 종료 신호 보냄
                response.setActionType(nextMsg.contains("완성") ? "FINISH" : "SPEAK");
                break;

            case "PREVIOUS":
                String repeatMsg = cookingSessionService.repeatStep(currentUser);
                response.setMessage(repeatMsg);
                response.setActionType("SPEAK");
                break;

            case "TIMER":
                int seconds = command.getTimerSeconds();
                response.setMessage(seconds / 60 + "분 타이머를 설정할게요.");
                response.setActionType("TIMER_START");
                response.setTimerSeconds(seconds);
                break;

            default:
                response.setMessage("잘 이해하지 못했어요. 다시 말씀해주세요.");
                response.setActionType("SPEAK");
        }

        return ResponseEntity.ok(response);
    }

    /**
     * 3. [클릭용] 레시피 아이디로 바로 조리 시작
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

    // 👇 [수정 2] 에러 났던 findCurrentUser 메서드를 여기에 구현했습니다.
    private User findCurrentUser(Principal principal) {
        if (principal == null) {
            throw new IllegalArgumentException("로그인 정보가 없습니다.");
        }
        String uid = principal.getName();
        return userRepository.findByUid(uid)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 사용자입니다. UID: " + uid));
    }
    /**
     * [TTS] 텍스트를 음성(MP3)으로 변환 (GPT 버전)
     * POST /api/chatbot/tts
     * Body: { "text": "안녕하세요 요리를 시작합니다" }
     */
    @PostMapping("/tts")
    public ResponseEntity<byte[]> generateVoice(@RequestBody Map<String, String> request) {
        String text = request.get("text");

        // 👇 [수정] 네이버 대신 GPT 클라이언트 사용
        byte[] audioBytes = gptApiClient.generateTts(text);

        if (audioBytes == null) {
            return ResponseEntity.internalServerError().build();
        }

        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType("audio/mpeg")) // MP3 헤더 설정
                .body(audioBytes);
    }
}