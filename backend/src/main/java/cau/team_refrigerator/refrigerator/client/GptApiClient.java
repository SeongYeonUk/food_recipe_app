package cau.team_refrigerator.refrigerator.client;

import cau.team_refrigerator.refrigerator.domain.dto.CookingCommandDto;
import cau.team_refrigerator.refrigerator.domain.dto.RecipeRecommendationRequestDto;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@Component
@RequiredArgsConstructor
public class GptApiClient {

    @Value("${openai.api-key}")
    private String openAiApiKey;

    private final String openAiApiUrl = "https://api.openai.com/v1/chat/completions";
    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * 1. [재료 추출] STT 텍스트 -> 재료 JSON 배열 String 반환
     */
    public String callGptApi(String sttText) {
        String today = LocalDate.now().toString();

        // 👇👇👇 [수정된 프롬프트] Priority 3 규칙을 변경했습니다! 👇👇👇
        String systemPrompt = """
            You are a smart data entry assistant for a refrigerator app.
            Your task is to analyze the user's input text and extract all food ingredients mentioned.
            Today's date is %s.
            
            ### Instructions:
            1. Extract one or more ingredients from the [USER_INPUT].
            2. Format the output as a JSON array named `ingredients`.
            3. Each object in the array must strictly follow this schema:
                * `name`: The name of the ingredient (String).
                * `quantity`: The quantity (Number). If not mentioned, default to 1.
                * `unit`: The unit (String). Examples: "개", "g", "ml", "팩", "통". If not mentioned, default to "개".
                * `category`: Must be ONE of the following:
                  [ "채소", "과일", "육류", "어패류", "유제품", "가공식품", "음료", "곡물", "기타"]
                * `expirationDate`: The expiration date (String), MUST be in YYYY-MM-DD format.
                                   Handle dates based on these priorities:
                                   - Priority 1 (Full Date): If the user says a full date like "2025년 7월 7일", parse it to "2025-07-07".
                                   - Priority 2 (Partial Date): If the user says a partial date like "7월 7일" or "11월 20일", use the year from today to format it.
                                   
                                   // ⭐ [핵심 수정] 유통기한 자동 추천 로직 ⭐
                                   - Priority 3 (Auto-Recommendation): If NO expiration date is mentioned, YOU MUST ESTIMATE a recommended expiration date based on general food shelf life standards.
                                     * Calculation: Today + [Typical Shelf Life Days for the ingredient]
                                     * Logic Examples:
                                       - Leafy Vegetables (Lettuce, Spinach): Today + 5~7 days
                                       - Milk/Dairy: Today + 7~10 days
                                       - Eggs: Today + 14~21 days
                                       - Tofu: Today + 3~5 days
                                       - Fresh Meat/Fish: Today + 3 days
                                       - Frozen items: Today + 30 days
                                     * Output: The CALCULATED future date in YYYY-MM-DD format.
            
            4. If unsure about the category, always use "기타".
            5. Output ONLY the JSON array.
            """.formatted(today);

        // 공통 메서드 호출 (String 반환)
        return callGptCommon(systemPrompt, sttText, String.class);
    }

    /**
     * 2. [레시피 추천 조건] STT -> 검색 조건 DTO 반환
     */
    public RecipeRecommendationRequestDto getRecipeSearchCondition(String sttText) {
        String systemPrompt = """
            You are a smart cooking assistant.
            Analyze [USER_INPUT] and extract search conditions.
            
            ### Output Format (JSON Only):
            {
              "useExpiringIngredients": boolean,
              "tastePreference": string or null,
              "mustUseIngredients": ["ing1", "ing2"],
              "timeLimitMinutes": integer or null,
              "missingIngredient": string or null,
              "substituteIngredients": ["sub1", "sub2"]
            }
            
            ### Rules for `substituteIngredients` (EXTREMELY IMPORTANT):
            1. Output ONLY the ingredient NAME (Noun).
            2. REMOVE all verbs, prepositions, and explanations like "instead of", "use", "mix", "water for milk".
            3. Split mixed ingredients into separate strings.
            
            ### Examples:
            - User: "Milk substitute?" -> GPT: ["Soy milk", "Water", "Cream"] (NOT "Water instead of milk")
            - User: "Butter substitute?" -> GPT: ["Oil", "Margarine"]
            - User: "No heavy cream" -> GPT: ["Milk", "Butter"] (Split "Milk + Butter" into two)
            """;

        return callGptCommon(systemPrompt, sttText, RecipeRecommendationRequestDto.class);
    }

    /**
     * 3. [조리 명령 분석] STT -> 조리 명령 DTO 반환
     */
    public CookingCommandDto parseCookingCommand(String sttText) {
        String systemPrompt = """
            Analyze [USER_INPUT] for cooking assistance.
            
            ### Intents:
            - "NEXT": Move to next step ("다음", "넘어가자", "다 했어")
            - "PREVIOUS": Repeat/Back ("다시", "이전", "못 들었어")
            - "TIMER": Set timer ("3분 타이머", "10분 뒤 알려줘")
            - "START": Start cooking ("김치찌개 시작", "이걸로 할게")
            
            ### Output Format (JSON Only):
            {
              "intent": "NEXT" | "PREVIOUS" | "TIMER" | "START",
              "timerSeconds": integer (Convert time to seconds for TIMER. e.g. 3min -> 180),
              "recipeName": string (Extract recipe name for START command)
            }
            """;

        return callGptCommon(systemPrompt, sttText, CookingCommandDto.class);
    }
    /**
     * 4. [유통기한 추천] 재료 이름만 주면 권장 유통기한(YYYY-MM-DD)을 반환
     * 사용처: 바코드, OCR, 직접 입력 시 날짜 자동완성용
     */
    public String recommendExpirationDate(String ingredientName) {
        String today = LocalDate.now().toString();

        String systemPrompt = """
            You are a food shelf-life calculator.
            Analyze the ingredient NAME and STATE to calculate the expiration date.
            Today is %s.
            
            ### Logic Flow (Apply in order):
            
            1. **Check State First**:
               - If name implies "Frozen" (냉동): +30 days
               - If name implies "Dried" (말린, 건): +180 days
               - If name implies "Canned" (통조림, 캔): +365 days
            
            2. **Check Ingredient Type**:
               - **Root Veggies** (Potato/감자, Onion/양파, Carrot/당근, Radish/무, Garlic/마늘): +21 days
               - **Hard Fruits** (Apple/사과, Pear/배, Melon/메론, Persimmon/감): +21 days
               - **Citrus** (Orange/오렌지, Lemon/레몬, Tangerine/귤): +14 days
               - **Eggs** (Egg/계란/달걀): +21 days
               - **Sauces** (Ketchup/케첩, Mayo/마요, Soy Sauce/간장): +90 days
               - **Beverages** (Cola/콜라, Juice/주스, Water/물): +90 days
               - **Kimchi/Side dishes** (Kimchi/김치, Pickles/장아찌): +30 days
               - **Tofu/Meat/Fish** (Tofu/두부, Pork/돼지고기, Beef/소고기): +5 days
               - **Leafy/Soft Veggies** (Lettuce/상추, Spinach/시금치, Cucumber/오이): +7 days
               - **Soft Fruits** (Strawberry/딸기, Banana/바나나, Grape/포도): +7 days
               
            3. **Default (If unsure)**:
               - Default: +7 days.
            
            4. **Output**:
               - ONLY the date in YYYY-MM-DD format.
            """.formatted(today);

        String userPrompt = "Ingredient Name: " + ingredientName;

        // 👇👇👇 [수정됨] 변수명을 resultText로 통일했습니다! 👇👇👇
        String resultText = callGptCommon(systemPrompt, userPrompt, String.class);

        if (resultText != null) {
            java.util.regex.Matcher matcher = java.util.regex.Pattern.compile("\\d{4}-\\d{2}-\\d{2}").matcher(resultText);
            if (matcher.find()) {
                return matcher.group();
            }
        }
        return LocalDate.now().plusDays(7).toString();
    }
    // [데이터 보정용] 레시피 재료를 1인분 기준으로 변환 요청
    public Map<String, String> normalizeIngredients(String recipeName, Map<String, String> originalIngredients) {
        try {
            StringBuilder ingredientsText = new StringBuilder();
            originalIngredients.forEach((name, amount) ->
                    ingredientsText.append(name).append(": ").append(amount).append(", ")
            );

            String systemPrompt = """
                You are a professional chef specializing in single-person households.
                Your task is to convert ingredient amounts to **strictly 1 PERSON (1 Serving)**.
                
                ### Critical Rules:
                1. **Detect Original Servings**: If the amounts seem large (e.g., 10 cucumbers, 1 cup of oil), assume it is a bulk recipe (e.g., 4-10 servings).
                2. **Scale Down**: You MUST divide the amounts to make it suitable for 1 person.
                   - Example: "Oil 1.5 cups" -> "1 tablespoon" (because 1.5 cups is too much for 1 person).
                   - Example: "Kimchi 10 heads" -> "0.25 head" or "300g".
                3. **Unit Conversion**: If the original unit is too big for 1 person (e.g., "cup" for oil), change it to "tablespoon" or "teaspoon".
                
                ### Output Format (JSON Only):
                { "IngredientName": "Scaled Amount" }
                """;

            String userPrompt = String.format("Recipe: %s\nIngredients: %s", recipeName, ingredientsText);

            // callGptCommon이 Map을 반환하도록 제네릭이 잘 되어 있는지 확인 필요.
            // 만약 String만 반환한다면 여기서 objectMapper.readValue(...)를 직접 써야 함.
            String jsonResponse = callGptCommon(systemPrompt, userPrompt, String.class);

            if (jsonResponse == null) {
                System.err.println("❌ GPT 응답이 null입니다. (Timeout 또는 API 오류)");
                return null;
            }

            System.out.println("🔍 GPT Raw Response: " + jsonResponse); // 응답 내용 확인

            return objectMapper.readValue(jsonResponse, new com.fasterxml.jackson.core.type.TypeReference<Map<String, String>>() {});

        } catch (Exception e) {
            // 👇 [수정] 에러 메시지를 자세히 출력
            System.err.println("❌ Normalization Fail (" + recipeName + "): " + e.getMessage());
            e.printStackTrace(); // 스택 트레이스 출력
            return null;
        }
    }

    // ==================================================================================
    // 👇👇👇 [신규 추가] GPT TTS 기능 (텍스트 -> MP3 변환) 👇👇👇
    // ==================================================================================
    public byte[] generateTts(String text) {
        String ttsApiUrl = "https://api.openai.com/v1/audio/speech";

        try {
            // 1. 요청 바디 구성 (모델: tts-1, 목소리: nova)
            Map<String, Object> requestPayload = Map.of(
                    "model", "tts-1",
                    "input", text,
                    "voice", "nova"
            );
            String jsonBody = objectMapper.writeValueAsString(requestPayload);

            // 2. 헤더 설정
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(openAiApiKey);

            // 3. API 호출 (바이너리 응답 받기)
            RestTemplate restTemplate = new RestTemplate();
            HttpEntity<String> entity = new HttpEntity<>(jsonBody, headers);

            // 중요: byte[] 클래스로 응답을 받습니다.
            ResponseEntity<byte[]> response = restTemplate.postForEntity(ttsApiUrl, entity, byte[].class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                return response.getBody();
            } else {
                throw new RuntimeException("GPT TTS 응답이 비어있습니다.");
            }

        } catch (Exception e) {
            System.err.println("GPT TTS 생성 실패: " + e.getMessage());
            return null;
        }
    }

    // ==================================================================================
    // 공통 메서드 (Chat Completion용)
    // ==================================================================================
    private <T> T callGptCommon(String systemPrompt, String userText, Class<T> responseType) {
        try {
            Map<String, Object> requestPayload = Map.of(
                    "model", "gpt-3.5-turbo",
                    "messages", List.of(
                            Map.of("role", "system", "content", systemPrompt),
                            Map.of("role", "user", "content", "[USER_INPUT]: " + userText)
                    )
            );
            String jsonBody = objectMapper.writeValueAsString(requestPayload);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(openAiApiKey);

            RestTemplate restTemplate = new RestTemplate();
            HttpEntity<String> entity = new HttpEntity<>(jsonBody, headers);
            String response = restTemplate.postForObject(openAiApiUrl, entity, String.class);

            String content = parseGptContent(response);

            if (responseType == String.class) {
                return responseType.cast(content);
            }
            return objectMapper.readValue(content, responseType);

        } catch (Exception e) {
            System.err.println("GPT API 호출 실패: " + e.getMessage());
            try {
                if (responseType == String.class) return responseType.cast("[]");
                return responseType.getDeclaredConstructor().newInstance();
            } catch (Exception ex) {
                return null;
            }
        }
    }

    private String parseGptContent(String gptJsonResponse) throws JsonProcessingException {
        JsonNode rootNode = objectMapper.readTree(gptJsonResponse);
        String content = rootNode.path("choices").path(0).path("message").path("content").asText();
        return content.replace("```json", "").replace("```", "").trim();
    }
}