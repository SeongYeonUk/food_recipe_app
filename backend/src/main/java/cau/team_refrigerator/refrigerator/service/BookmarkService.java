package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.domain.Bookmark;
import cau.team_refrigerator.refrigerator.domain.Favorite;
import cau.team_refrigerator.refrigerator.domain.Recipe;
import cau.team_refrigerator.refrigerator.domain.User;
import cau.team_refrigerator.refrigerator.domain.dto.BookmarkResponseDto;
import cau.team_refrigerator.refrigerator.repository.BookmarkRepository;
import cau.team_refrigerator.refrigerator.repository.FavoriteRepository;
import cau.team_refrigerator.refrigerator.repository.RecipeRepository;
import cau.team_refrigerator.refrigerator.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true) // 기본적으로는 읽기 전용으로 설정
public class BookmarkService {

    private final BookmarkRepository bookmarkRepository;
    private final UserRepository userRepository;
    private final RecipeRepository recipeRepository; // 'AI 추천 레시피' Repository
    private final FavoriteRepository favoriteRepository; // '나만의 레시피' Repository

    // --- 북마크 추가 ---
    @Transactional // 쓰기 작업이므로 @Transactional을 개별적으로 적용
    public void addBookmark(Long userId, Long recipeId, String recipeType) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("사용자를 찾을 수 없습니다. ID: " + userId));

        // 1. 레시피 타입 유효성 검사
        if (!"AI".equals(recipeType) && !"CUSTOM".equals(recipeType)) {
            throw new IllegalArgumentException("잘못된 레시피 타입입니다: " + recipeType);
        }

        // 2. 실제 레시피가 존재하는지 확인 (데이터 무결성)
        if ("AI".equals(recipeType)) {
            if (!recipeRepository.existsById(recipeId)) {
                throw new EntityNotFoundException("AI 레시피를 찾을 수 없습니다. ID: " + recipeId);
            }
        } else { // "CUSTOM"
            if (!favoriteRepository.existsById(recipeId)) {
                throw new EntityNotFoundException("나만의 레시피를 찾을 수 없습니다. ID: " + recipeId);
            }
        }

        // 3. 이미 북마크에 추가되었는지 확인
        bookmarkRepository.findByUserAndRecipeIdAndRecipeType(user, recipeId, recipeType)
                .ifPresent(b -> {
                    throw new IllegalStateException("이미 북마크에 추가된 레시피입니다.");
                });

        // 4. 북마크 저장
        Bookmark bookmark = new Bookmark(user, recipeId, recipeType);
        bookmarkRepository.save(bookmark);
    }

    // --- 북마크 삭제 ---
    @Transactional // 쓰기 작업
    public void removeBookmark(Long userId, Long recipeId, String recipeType) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("사용자를 찾을 수 없습니다. ID: " + userId));

        Bookmark bookmark = bookmarkRepository.findByUserAndRecipeIdAndRecipeType(user, recipeId, recipeType)
                .orElseThrow(() -> new EntityNotFoundException("해당 북마크를 찾을 수 없습니다."));

        bookmarkRepository.delete(bookmark);
    }

    // --- 나의 북마크 목록 조회 ---
    public List<BookmarkResponseDto> getMyBookmarks(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("사용자를 찾을 수 없습니다. ID: " + userId));

        List<Bookmark> bookmarks = bookmarkRepository.findAllByUser(user);

        // 북마크 목록을 기반으로 실제 레시피 정보를 DTO 리스트로 변환하여 반환
        return bookmarks.stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    // --- 북마크 엔티티를 응답 DTO로 변환하는 헬퍼 메소드 ---
    private BookmarkResponseDto convertToDto(Bookmark bookmark) {
        String recipeType = bookmark.getRecipeType();
        Long recipeId = bookmark.getRecipeId();

        // 1. "AI 추천 레시피"인 경우
        if ("AI".equals(recipeType)) {
            Recipe recipe = recipeRepository.findById(recipeId)
                    .orElse(null);

            if (recipe != null) {
                return new BookmarkResponseDto(
                        recipe.getId(),
                        recipe.getTitle(),      // getName() -> getTitle()로 변경
                        recipe.getImageUrl(),
                        "AI"
                );
            }

            // 2. "나만의 레시피"인 경우
        } else if ("CUSTOM".equals(recipeType)) {
            Favorite favorite = favoriteRepository.findById(recipeId)
                    .orElse(null);

            if (favorite != null) {
                Recipe customRecipe = favorite.getRecipe();

                return new BookmarkResponseDto(
                        favorite.getId(),
                        customRecipe.getTitle(), // getName() -> getTitle()로 변경
                        customRecipe.getImageUrl(),
                        "CUSTOM"
                );
            }
        }

        return null;
    }
}