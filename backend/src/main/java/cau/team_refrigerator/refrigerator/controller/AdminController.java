package cau.team_refrigerator.refrigerator.controller;

import cau.team_refrigerator.refrigerator.service.RecipeNormalizationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {

    private final RecipeNormalizationService normalizationService;

    @PostMapping("/normalize-recipes")
    public ResponseEntity<String> runNormalization() {

        // ✅ [수정] 백그라운드 스레드에서 '전체 변환' 시작!
        // (이렇게 하면 Postman은 바로 응답을 받고, 서버 혼자 뒤에서 계속 일합니다.)
        new Thread(() -> normalizationService.normalizeAllRecipes()).start();

        return ResponseEntity.ok("전체 레시피 1인분 변환 작업이 시작되었습니다. 서버 로그(Console)를 확인하세요.");
    }
}