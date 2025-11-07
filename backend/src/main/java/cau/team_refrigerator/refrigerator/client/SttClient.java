package cau.team_refrigerator.refrigerator.client;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.HttpEntity; // 1. import 추가
import org.springframework.http.HttpHeaders; // 2. import 추가
import org.springframework.http.MediaType; // 3. import 추가
import java.util.Base64;
import com.fasterxml.jackson.core.JsonProcessingException; // 1. 추가
import com.fasterxml.jackson.databind.JsonNode; // 2. 추가
import com.fasterxml.jackson.databind.ObjectMapper; // 3. 추가

@Component
public class SttClient {
    @Value("${google.stt.api-key}")
    private final String apiKey;

    // @Value가 application.properties에서 "google.stt.api-key" 값을 찾아 주입합니다.
    public SttClient(@Value("${google.stt.api-key}") String apiKey) {
        this.apiKey = apiKey;
    }
    private final String sttUrl = "https://speech.googleapis.com/v1/speech:recognize?key=";

    public String callGoogleSttApi(byte[] audioBytes) {

        // 1. Base64 인코딩
        String base64Audio = Base64.getEncoder().encodeToString(audioBytes);

        // 2. JSON 요청 생성
        String requestJson = String.format(
                "{" +
                        "\"config\": {\"encoding\": \"LINEAR16\", \"sampleRateHertz\": 16" +
                        "000, \"languageCode\": \"ko-KR\"}," +
                        "\"audio\": {\"content\": \"%s\"}" +
                        "}", base64Audio
        );

        // 3. API 호출
        RestTemplate restTemplate = new RestTemplate();

        // --- 🚨 여기가 수정된 부분입니다 ---
        // (1) HttpHeaders 설정 (Content-Type을 JSON으로)
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        // (2) HttpEntity 생성 (헤더와 JSON 본문 결합)
        HttpEntity<String> entity = new HttpEntity<>(requestJson, headers);

        // (3) '/* entity */' 주석 대신 실제 'entity' 객체를 전달
        String response = restTemplate.postForObject(sttUrl + apiKey, entity, String.class);
        // --- 🚨 수정 끝 ---


        // 4. 텍스트 파싱
        // 디버깅을 위해 응답 원본을 콘솔에 출력
        System.out.println("Google STT 응답 원본: " + response);

        return parseTranscript(response);
    }

    private final ObjectMapper objectMapper = new ObjectMapper();

    private String parseTranscript(String jsonResponse) {
        try {
            JsonNode rootNode = objectMapper.readTree(jsonResponse);

            // JSON 경로 탐색: results[0].alternatives[0].transcript
            JsonNode transcriptNode = rootNode.path("results")
                    .path(0)
                    .path("alternatives")
                    .path(0)
                    .path("transcript");

            if (transcriptNode.isMissingNode()) {
                // 'results' 배열이 비어있거나 (예: 조용한 파일)
                // 'transcript' 필드를 찾을 수 없는 경우
                System.err.println("Google STT: 'transcript' 필드를 찾을 수 없습니다.");
                return "인식된 텍스트 없음 (transcript 필드 없음)";
            } else {
                return transcriptNode.asText();
            }

        } catch (JsonProcessingException e) {
            System.err.println("Google STT JSON 파싱 오류: " + e.getMessage());
            return "텍스트 파싱 실패 (JSON 오류)";
        }
    }
}