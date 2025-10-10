package cau.team_refrigerator.refrigerator.controller;

import cau.team_refrigerator.refrigerator.domain.User; // User 클래스를 import 합니다.
import cau.team_refrigerator.refrigerator.service.SpeechRecognitionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/speech")
@RequiredArgsConstructor
public class SpeechController {

    private final SpeechRecognitionService speechRecognitionService;

    @PostMapping("/recognize")
    public ResponseEntity<String> recognizeSpeech(
            @RequestParam("audioFile") MultipartFile audioFile,
            // --- [수정된 부분] ---
            // UserDetailsImpl 대신 User 객체를 직접 받습니다.
            @AuthenticationPrincipal User currentUser) {

        if (audioFile.isEmpty()) {
            return ResponseEntity.badRequest().body("오디오 파일이 비어있습니다.");
        }

        // currentUser가 null이면 로그인하지 않은 사용자이므로 접근을 거부합니다.
        if (currentUser == null) {
            return ResponseEntity.status(401).body("로그인이 필요합니다.");
        }

        try {
            byte[] audioData = audioFile.getBytes();

            // 서비스에 User 객체를 바로 전달합니다.
            String resultMessage = speechRecognitionService.recognizeAndLogSpeech(audioData, currentUser);

            return ResponseEntity.ok(resultMessage);

        } catch (Exception e) {
            return ResponseEntity.status(500).body("처리 중 오류 발생: " + e.getMessage());
        }
    }
}