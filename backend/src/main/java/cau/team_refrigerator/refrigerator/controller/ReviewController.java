package cau.team_refrigerator.refrigerator.controller;

import cau.team_refrigerator.refrigerator.domain.User;
import cau.team_refrigerator.refrigerator.domain.dto.ReviewCreateRequestDto;
import cau.team_refrigerator.refrigerator.domain.dto.ReviewResponseDto;
import cau.team_refrigerator.refrigerator.domain.dto.ReviewUpdateRequestDto;
import cau.team_refrigerator.refrigerator.service.ReviewService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.nio.file.AccessDeniedException;
import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api")
public class ReviewController {

    private final ReviewService reviewService;

    /**
     * 특정 레시피에 대한 후기 작성
     * POST /api/recipes/{recipeId}/reviews
     */
    @PostMapping("/recipes/{recipeId}/reviews")
    public ResponseEntity<Long> createReview(
            @PathVariable Long recipeId,
            @RequestBody ReviewCreateRequestDto requestDto,
            @AuthenticationPrincipal User user) { // ⭐️ 현재 로그인된 사용자 정보

        Long reviewId = reviewService.createReview(recipeId, requestDto, user);

        // 생성된 리뷰 ID와 함께 201 Created 응답 반환
        return ResponseEntity.status(201).body(reviewId);
    }

    /**
     * 특정 레시피의 모든 후기 조회
     * GET /api/recipes/{recipeId}/reviews
     */
    @GetMapping("/recipes/{recipeId}/reviews")
    public ResponseEntity<List<ReviewResponseDto>> getReviews(
            @PathVariable Long recipeId,
            @AuthenticationPrincipal User user) { // ⭐️ 비로그인 사용자도 조회 가능 (user가 null일 수 있음)

        List<ReviewResponseDto> reviews = reviewService.getReviewsByRecipeId(recipeId, user);
        return ResponseEntity.ok(reviews);
    }

    /**
     * 후기 수정
     * PUT /api/reviews/{reviewId}
     */
    @PutMapping("/reviews/{reviewId}")
    public ResponseEntity<Void> updateReview(
            @PathVariable Long reviewId,
            @RequestBody ReviewUpdateRequestDto requestDto,
            @AuthenticationPrincipal User user) {

        try {
            reviewService.updateReview(reviewId, requestDto, user);
            return ResponseEntity.ok().build(); // 성공 (200 OK)
        } catch (AccessDeniedException e) {
            return ResponseEntity.status(403).build(); // 권한 없음 (403 Forbidden)
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(404).build(); // 찾을 수 없음 (404 Not Found)
        }
    }

    /**
     * 후기 삭제
     * DELETE /api/reviews/{reviewId}
     */
    @DeleteMapping("/reviews/{reviewId}")
    public ResponseEntity<Void> deleteReview(
            @PathVariable Long reviewId,
            @AuthenticationPrincipal User user) {

        try {
            reviewService.deleteReview(reviewId, user);
            return ResponseEntity.noContent().build(); // 성공 (204 No Content)
        } catch (AccessDeniedException e) {
            return ResponseEntity.status(403).build(); // 권한 없음 (403 Forbidden)
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(404).build(); // 찾을 수 없음 (404 Not Found)
        }
    }
}