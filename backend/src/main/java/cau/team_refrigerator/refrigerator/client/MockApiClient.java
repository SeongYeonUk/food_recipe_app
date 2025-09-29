package cau.team_refrigerator.refrigerator.client;

import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;
import org.springframework.util.StreamUtils;
import java.io.IOException;
import java.nio.charset.StandardCharsets;

@Component
public class MockApiClient {

    public String searchRecipes(String query) {
        // query와 상관없이 항상 같은 mock 파일을 반환합니다.
        return readJsonFile("mock-data/recipe-search-response.json");
    }

    public String searchRecipeCourse(String recipeId) {
        return readJsonFile("mock-data/recipe-course-response.json");
    }

    // 파일을 읽어오는 공통 메소드
    private String readJsonFile(String path) {
        try {
            var resource = new ClassPathResource(path);
            return StreamUtils.copyToString(resource.getInputStream(), StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new RuntimeException("Mock 데이터 파일을 읽는 데 실패했습니다: " + path, e);
        }
    }
}