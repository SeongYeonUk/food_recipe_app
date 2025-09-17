package cau.team_refrigerator.refrigerator.controller;

import cau.team_refrigerator.refrigerator.domain.User;
import cau.team_refrigerator.refrigerator.domain.dto.PopularIngredientDto;
import cau.team_refrigerator.refrigerator.domain.dto.PopularRecipeDto;
import cau.team_refrigerator.refrigerator.service.StatisticsService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import java.util.List;

@RestController
@RequestMapping("/api/statistics")
@RequiredArgsConstructor
public class StatisticsController {

    private final StatisticsService statisticsService;

    @GetMapping("/ingredients")
    public ResponseEntity<List<PopularIngredientDto>> getPopularIngredients(
            @RequestParam(required = false) String period) {

        List<PopularIngredientDto> popularIngredients = statisticsService.getPopularIngredients(period);
        return ResponseEntity.ok(popularIngredients);
    }

    @GetMapping("/recipes")
    public ResponseEntity<List<PopularRecipeDto>> getPopularRecipes(
            @RequestParam(required = false) String period,
            @AuthenticationPrincipal User user) {

        List<PopularRecipeDto> popularRecipes = statisticsService.getPopularRecipes(period, user);
        return ResponseEntity.ok(popularRecipes);
    }
}