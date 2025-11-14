// /client/GptApiClient.java

package cau.team_refrigerator.refrigerator.client;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import com.fasterxml.jackson.core.JsonProcessingException;
import java.util.Arrays; // 2. 추가
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.time.LocalDate;

@Component
public class GptApiClient {

    // 🚨🚨🚨
    // .properties 파일에 OpenAI API 키를 추가하세요!
    // 예: openai.api-key=sk-xxxx...
    // 🚨🚨🚨
    @Value("${openai.api-key}")
    private final String openAiApiKey;

    // @Value가 application.properties에서 "openai.api-key" 값을 찾아 주입합니다.
    public GptApiClient(@Value("${openai.api-key}") String openAiApiKey) {
        this.openAiApiKey = openAiApiKey;
    }

    private final String openAiApiUrl = "https://api.openai.com/v1/chat/completions";
    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * STT로 변환된 텍스트를 받아 GPT API로 전송하고, 분석된 JSON을 받습니다.
     */
    // /client/GptApiClient.java (메소드 교체)

    public String callGptApi(String sttText) {

        // 1. HTTP 헤더 설정 (OpenAI 인증 토큰 포함)
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(openAiApiKey); // "Authorization: Bearer sk-..."

        // 2. ⭐️ 프롬프트 엔지니어링 적용 (카테고리 목록 업데이트) ⭐️
        String systemPromptTemplate = """
            You are a smart data entry assistant for a refrigerator app.
            Your task is to analyze the user's input text and extract all food ingredients mentioned.

            ### Instructions:
            1. Extract one or more ingredients from the [USER_INPUT].
            2. Format the output as a JSON array named `ingredients`.
            3. Each object in the array must strictly follow this schema:
                * `name`: The name of the ingredient (String).
                * `quantity`: The quantity (Number). If not mentioned, default to 1.
                * `unit`: The unit (String). Examples: "개", "g", "ml", "팩", "통". If not mentioned, default to "개".
                * `category`: Must be ONE of the following:
                  [ "채소", "과일", "육류", "어패류", "유제품", "가공식품", "음료", "곡물", "기타" ]
                * `expirationDate`: The expiration date (String). 
                                   MUST be in YYYY-MM-DD format. 
                                   If not mentioned, default to null.
            4. If unsure about the category, always use "기타".
            5. Your response must be ONLY the JSON array. Do not include any other text.
            6. Today's date is [{{TODAY_DATE}}]. 
               If the user mentions a specific date (e.g., "11월 20일"), 
               use today's date to determine the correct year and format it as YYYY-MM-DD.
            """;

        // 2.5. 오늘 날짜를 계산하여 프롬프트에 주입 (이전과 동일)
        String today = LocalDate.now().toString(); // "2025-11-08"
        String systemPrompt = systemPromptTemplate.replace("{{TODAY_DATE}}", today);

        // 3. ⭐️⭐️⭐️ 여기가 수정된 핵심입니다 ⭐️⭐️⭐️
        // String.format 대신 Java 객체(Map/List)로 요청 본문을 만듭니다.
        Map<String, Object> systemMessage = new HashMap<>();
        systemMessage.put("role", "system");
        systemMessage.put("content", systemPrompt); // ObjectMapper가 알아서 이스케이프 처리

        Map<String, Object> userMessage = new HashMap<>();
        userMessage.put("role", "user");
        userMessage.put("content", "[USER_INPUT]: " + sttText);

        Map<String, Object> requestPayload = new HashMap<>();
        requestPayload.put("model", "gpt-3.5-turbo");
        requestPayload.put("messages", Arrays.asList(systemMessage, userMessage));

        String requestJsonBody;
        try {
            // ObjectMapper가 Java Map을 완벽한 JSON 문자열로 변환 (줄바꿈/따옴표 자동 처리)
            requestJsonBody = objectMapper.writeValueAsString(requestPayload);
        } catch (JsonProcessingException e) {
            System.err.println("GPT 요청 JSON 생성 실패: " + e.getMessage());
            return "[]"; // 이 오류는 거의 발생하지 않음
        }
        // --- ⭐️⭐️⭐️ 수정 끝 ⭐️⭐️⭐️

        // 4. API 호출
        HttpEntity<String> entity = new HttpEntity<>(requestJsonBody, headers);
        RestTemplate restTemplate = new RestTemplate();

        try {
            String response = restTemplate.postForObject(openAiApiUrl, entity, String.class);

            // 5. GPT 응답(JSON)에서 'content' (우리가 원하는 JSON)만 파싱
            return parseGptResponse(response);

        } catch (Exception e) {
            System.err.println("GPT API 호출 오류: " + e.getMessage());
            return "[]"; // 오류 시 빈 배열 반환
        }
    }

    // (parseGptResponse 메소드는 수정할 필요 없이 그대로 둡니다)

    /**
     * OpenAI의 복잡한 응답 JSON에서 content 부분만 추출합니다.
     */
    private String parseGptResponse(String gptJsonResponse) {
        try {
            JsonNode rootNode = objectMapper.readTree(gptJsonResponse);
            // JSON 경로: choices[0].message.content
            String content = rootNode.path("choices")
                    .path(0)
                    .path("message")
                    .path("content")
                    .asText();

            // GPT가 `[{"name":...}]` 대신 ```json\n[{"name":...}]\n``` 처럼
            // 마크다운 코드 블록을 반환할 때를 대비한 정리
            content = content.replace("```json\n", "").replace("\n```", "").trim();

            return content;

        } catch (Exception e) {
            System.err.println("GPT JSON 응답 파싱 오류: " + e.getMessage());
            return "[]"; // 파싱 실패 시 빈 배열
        }
    }
}
