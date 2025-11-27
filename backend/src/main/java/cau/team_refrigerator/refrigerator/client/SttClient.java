package cau.team_refrigerator.refrigerator.client;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.util.Base64;

@Component
public class SttClient {

    private final String apiKey;
    private final String sttUrl = "https://speech.googleapis.com/v1/speech:recognize?key=";
    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    // 1. ⭐️ [수정] 생성자에서만 @Value를 사용하도록 정리 (필드 @Value 제거)
    public SttClient(@Value("${google.stt.api-key}") String apiKey) {
        this.apiKey = apiKey;
    }

    public String callGoogleSttApi(byte[] audioBytes) {

        // 1. Base64 인코딩
        String base64Audio = Base64.getEncoder().encodeToString(audioBytes);

        // --- ⬇️ ⬇️ ⬇️ [핵심 수정] ⬇️ ⬇️ ⬇️ ---
        // 2. JSON 요청 수정:
        //    encoding은 'LINEAR16' (WAV)
        //    sampleRateHertz를 44100에서 16000으로 원복
        String requestJson = String.format(
                "{" +
                        "\"config\": {\"encoding\": \"LINEAR16\", \"sampleRateHertz\": 16000, \"languageCode\": \"ko-KR\"}," +
                        "\"audio\": {\"content\": \"%s\"}" +
                        "}", base64Audio
        );
        // --- ⬆️ ⬆️ ⬆️ [핵심 수정 끝] ⬆️ ⬆️ ⬆️ ---

        // 3. API 호출
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<String> entity = new HttpEntity<>(requestJson, headers);

        String response = restTemplate.postForObject(sttUrl + apiKey, entity, String.class);

        // 4. 텍스트 파싱 (디버깅 로그 포함)
        System.out.println("Google STT 응답 원본: " + response);
        return parseTranscript(response);
    }

    private String parseTranscript(String jsonResponse) {
        try {
            JsonNode rootNode = objectMapper.readTree(jsonResponse);

            JsonNode transcriptNode = rootNode.path("results")
                    .path(0)
                    .path("alternatives")
                    .path(0)
                    .path("transcript");

            if (transcriptNode.isMissingNode()) {
                System.err.println("Google STT: 'transcript' 필드를 찾을 수 없습니다.");
                return "인식된 텍스트 없음 (transcript 필드 없음)"; // ⭐️ SttService가 인식하는 메시지
            } else {
                return transcriptNode.asText();
            }

        } catch (JsonProcessingException e) {
            System.err.println("Google STT JSON 파싱 오류: " + e.getMessage());
            return "텍스트 파싱 실패 (JSON 오류)";
        }
    }
}