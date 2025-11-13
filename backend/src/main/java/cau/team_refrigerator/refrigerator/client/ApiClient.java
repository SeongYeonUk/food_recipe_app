package cau.team_refrigerator.refrigerator.client;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.net.URI;

@Component
public class ApiClient {

    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${nongsang.api.base-url}")
    private String baseUrl;

    @Value("${nongsang.api.service-key}")
    private String serviceKey;

    @Value("${nongsang.api.service-id.basic}")
    private String recipeBasicServiceId;

    @Value("${nongsang.api.service-id.ingredient}")
    private String recipeIngredientServiceId;

    @Value("${nongsang.api.service-id.course}")
    private String recipeCourseServiceId;

    /**
     * 레시피 기본 정보를 검색합니다. (사용자 실시간 검색용)
     */
    public String searchRecipes(String query) {
        URI uri = UriComponentsBuilder
                .fromUriString(baseUrl)
                .path("/openapi/{apiKey}/{type}/{serviceId}/{startIndex}/{endIndex}") // 1~100 페이지만 검색
                .queryParam("RECIPE_NM_KO", query)
                .encode()
                .buildAndExpand(
                        serviceKey,
                        "json",
                        recipeBasicServiceId,
                        "1",                  // (수정) 1페이지 고정
                        "100"                 // (수정) 100개 고정
                )
                .toUri();
        return executeApiCall(uri, "레시피 기본 정보 조회");
    }

    // 👇👇👇 [신규 추가] 배치 작업용 메소드 👇👇👇
    /**
     * (신규) 모든 레시피를 페이징하여 가져옵니다. (배치 작업용)
     */
    public String getAllRecipesForBatch(int startIndex, int endIndex) {
        URI uri = UriComponentsBuilder
                .fromUriString(baseUrl)
                .path("/{apiKey}/{type}/{serviceId}/{startIndex}/{endIndex}") // 경로에 변수 사용
                .encode() // <-- queryParam이 없으므로 여기서 encode()
                .buildAndExpand(
                        serviceKey,           // {apiKey}
                        "json",               // {type}
                        recipeBasicServiceId, // {serviceId}
                        startIndex,           // {startIndex}
                        endIndex              // {endIndex}
                )
                .toUri();
        return executeApiCall(uri, "배치 - 레시피 기본 정보 조회 (" + startIndex + "~" + endIndex + ")");
    }


    /**
     * 레시피 재료 정보를 검색합니다. (수정됨)
     */
    public String searchIngredients(String recipeId) {
        URI uri = UriComponentsBuilder
                .fromUriString(baseUrl)
                .path("/{apiKey}/{type}/{serviceId}/{startIndex}/{endIndex}")
                .queryParam("RECIPE_ID", recipeId)
                .encode()
                .buildAndExpand(
                        serviceKey,
                        "json",
                        recipeIngredientServiceId,
                        "1",
                        "100" // 재료는 100개면 충분할 것으로 예상
                )
                .toUri();
        return executeApiCall(uri, "레시피 재료 정보 조회");
    }

    /**
     * 레시피 요리 과정을 검색합니다. (수정됨)
     */
    public String searchRecipeCourse(String recipeId) {
        URI uri = UriComponentsBuilder
                .fromUriString(baseUrl)
                .path("/{apiKey}/{type}/{serviceId}/{startIndex}/{endIndex}")
                .queryParam("RECIPE_ID", recipeId)
                .encode()
                .buildAndExpand(
                        serviceKey,
                        "json",
                        recipeCourseServiceId,
                        "1",
                        "100" // 과정도 100개면 충분할 것으로 예상
                )
                .toUri();
        return executeApiCall(uri, "레시피 요리 과정 조회");
    }

    // 공통 API 호출 로직
    private String executeApiCall(URI uri, String callName) {
        System.out.println(callName + " 요청 URI: " + uri);
        try {
            return restTemplate.getForObject(uri, String.class);
        } catch (RestClientException e) {
            System.err.println(callName + " API 호출 중 오류 발생: " + e.getMessage());
            return null;
        }
    }
}