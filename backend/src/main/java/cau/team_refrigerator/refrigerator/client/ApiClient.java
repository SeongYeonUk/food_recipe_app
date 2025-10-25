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

    // application.properties의 'nongsang.api.base-url' 키의 값을 찾아옵니다.
    @Value("${nongsang.api.base-url}")
    private String baseUrl;

    // application.properties의 'nongsang.api.service-key' 키의 값을 찾아옵니다.
    @Value("${nongsang.api.service-key}")
    private String serviceKey;

    @Value("${nongsang.api.service-id.basic}")
    private String recipeBasicServiceId;

    @Value("${nongsang.api.service-id.ingredient}")
    private String recipeIngredientServiceId;

    @Value("${nongsang.api.service-id.course}")
    private String recipeCourseServiceId;

    /**
     * 레시피 기본 정보를 검색합니다.
     */
    public String searchRecipes(String query) {
        URI uri = UriComponentsBuilder
                .fromUriString(baseUrl)
                .path("/{serviceId}/json/1/100")
                .queryParam("API_KEY", serviceKey)
                .queryParam("RECIPE_NM_KO", query)
                .encode()
                .buildAndExpand(recipeBasicServiceId)
                .toUri();
        return executeApiCall(uri, "레시피 기본 정보 조회");
    }

    /**
     * 레시피 재료 정보를 검색합니다.
     */
    public String searchIngredients(String recipeId) {
        URI uri = UriComponentsBuilder
                .fromUriString(baseUrl)
                .path("/{serviceId}/json/1/100")
                .queryParam("API_KEY", serviceKey)
                .queryParam("RECIPE_ID", recipeId)
                .encode()
                .buildAndExpand(recipeIngredientServiceId)
                .toUri();
        return executeApiCall(uri, "레시피 재료 정보 조회");
    }

    /**
     * 레시피 요리 과정을 검색합니다.
     */
    public String searchRecipeCourse(String recipeId) {
        URI uri = UriComponentsBuilder
                .fromUriString(baseUrl)
                .path("/{serviceId}/json/1/100")
                .queryParam("API_KEY", serviceKey)
                .queryParam("RECIPE_ID", recipeId)
                .encode()
                .buildAndExpand(recipeCourseServiceId)
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