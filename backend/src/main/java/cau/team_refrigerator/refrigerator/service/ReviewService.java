package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.domain.Recipe;
import cau.team_refrigerator.refrigerator.domain.Review;
import cau.team_refrigerator.refrigerator.domain.User;
import cau.team_refrigerator.refrigerator.domain.dto.ReviewCreateRequestDto;
import cau.team_refrigerator.refrigerator.domain.dto.ReviewResponseDto;
import cau.team_refrigerator.refrigerator.domain.dto.ReviewUpdateRequestDto;
import cau.team_refrigerator.refrigerator.repository.RecipeRepository;
import cau.team_refrigerator.refrigerator.repository.ReviewRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.file.AccessDeniedException;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class ReviewService {

    private final ReviewRepository reviewRepository;
    private final RecipeRepository recipeRepository; // ⭐️ 기존 RecipeRepository 주입

    /**
     * 레시피 후기 생성
     */
    public Long createReview(Long recipeId, ReviewCreateRequestDto requestDto, User user) {

        // 1. 후기를 작성할 레시피를 조회합니다.
        Recipe recipe = recipeRepository.findById(recipeId)
                .orElseThrow(() -> new IllegalArgumentException("해당 레시피를 찾을 수 없습니다. id=" + recipeId));

        // 2. 새로운 Review 엔티티를 생성합니다.
        Review review = new Review();
        review.setRecipe(recipe);
        review.setUser(user); // ⭐️ 인증된 사용자 정보
        review.setTitle(requestDto.getTitle());
        review.setContent(requestDto.getContent());
        review.setImageUrl(requestDto.getImageUrl());

        // 3. 리뷰를 저장합니다.
        Review savedReview = reviewRepository.save(review);

        return savedReview.getId(); // 생성된 리뷰의 ID 반환
    }

    /**
     * 특정 레시피의 모든 후기 조회
     */
    @Transactional(readOnly = true) // ⭐️ 조회 전용 트랜잭션
    public List<ReviewResponseDto> getReviewsByRecipeId(Long recipeId, User user) {
        // 1. 레시피 ID로 모든 리뷰를 찾습니다.
        List<Review> reviews = reviewRepository.findByRecipeId(recipeId);

        // 2. 현재 로그인한 사용자의 ID를 가져옵니다. (비로그인 시 null)
        Long currentUserId = (user != null) ? user.getId() : -1L; // 비로그인 사용자는 -1L로 처리

        // 3. 리뷰 목록을 ReviewResponseDto로 변환합니다.
        return reviews.stream()
                .map(review -> new ReviewResponseDto(review, currentUserId)) // ⭐️ DTO로 변환
                .collect(Collectors.toList());
    }

    /**
     * 후기 수정
     */
    public void updateReview(Long reviewId, ReviewUpdateRequestDto requestDto, User user) throws AccessDeniedException {
        // 1. 리뷰를 조회합니다.
        Review review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> new IllegalArgumentException("해당 후기를 찾을 수 없습니다. id=" + reviewId));

        // 2. ⭐️ 권한 확인: 현재 로그인한 사용자와 후기 작성자가 동일한지 확인
        if (!review.getUser().getId().equals(user.getId())) {
            throw new AccessDeniedException("후기를 수정할 권한이 없습니다.");
        }

        // 3. 내용 수정 (Dirty Checking)
        review.setTitle(requestDto.getTitle());
        review.setContent(requestDto.getContent());
        review.setImageUrl(requestDto.getImageUrl());
        // @Transactional 어노테이션으로 인해 메서드 종료 시 자동 저장됩니다.
    }

    /**
     * 후기 삭제
     */
    public void deleteReview(Long reviewId, User user) throws AccessDeniedException {
        // 1. 리뷰를 조회합니다.
        Review review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> new IllegalArgumentException("해당 후기를 찾을 수 없습니다. id=" + reviewId));

        // 2. ⭐️ 권한 확인
        if (!review.getUser().getId().equals(user.getId())) {
            throw new AccessDeniedException("후기를 삭제할 권한이 없습니다.");
        }

        // 3. 삭제
        reviewRepository.delete(review);
    }
}