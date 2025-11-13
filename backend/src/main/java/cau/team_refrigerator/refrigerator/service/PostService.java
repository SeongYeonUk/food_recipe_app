package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.domain.Post;
import cau.team_refrigerator.refrigerator.domain.Recipe;
import cau.team_refrigerator.refrigerator.domain.User;
// RecipeIngredient import (필요할 수 있음, 없어도 stream에서 자동 추론)
import cau.team_refrigerator.refrigerator.domain.RecipeIngredient;
import cau.team_refrigerator.refrigerator.domain.dto.PostListResponseDto;
import cau.team_refrigerator.refrigerator.domain.dto.PostResponseDto;
import cau.team_refrigerator.refrigerator.domain.dto.PostShareRequestDto;
import cau.team_refrigerator.refrigerator.domain.dto.PostUpdateRequestDto;
import cau.team_refrigerator.refrigerator.repository.PostRepository;
import cau.team_refrigerator.refrigerator.repository.RecipeRepository;
import cau.team_refrigerator.refrigerator.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PostService {

    private final PostRepository postRepository;
    private final UserRepository userRepository;
    private final RecipeRepository recipeRepository;

    /**
     * '나만의 레시피'를 '레시피 자랑' 게시글로 공유 (CREATE)
     * @param requestDto 공유할 Recipe ID가 담긴 DTO
     * @param userId (JWT 토큰에서 추출한) 사용자 ID
     * @return 생성된 Post 게시글 정보
     */
    @Transactional
    public PostResponseDto shareRecipeAsPost(PostShareRequestDto requestDto, Long userId) {

        // 1. 사용자(작성자) 정보 조회
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("해당 유저를 찾을 수 없습니다. id=" + userId));

        // 2. 공유할 원본 '나만의 레시피(Recipe)' 조회
        Recipe originalRecipe = recipeRepository.findById(requestDto.getRecipeId())
                .orElseThrow(() -> new IllegalArgumentException("공유할 레시피를 찾을 수 없습니다. id=" + requestDto.getRecipeId()));

        // 3. 'Recipe' 엔티티 정보를 'Post' 엔티티로 복사

        // 3-1. 재료 목록(List<RecipeIngredient>)을 String으로 변환
        String ingredientsString = originalRecipe.getRecipeIngredients().stream()
                // --- ⬇️ 여기를 수정했습니다 ⬇️ ---
                .map(ri -> ri.getIngredient().getName() + " " + ri.getAmount())
                // --- ⬆️ 'getQuantity()' -> 'getAmount()' ⬆️ ---
                .collect(Collectors.joining("\n")); // (\n = 줄바꿈)

        // 3-2. 조리 시간(Integer)을 String으로 변환 (예: 30 -> "30분")
        String cookTimeString = String.valueOf(originalRecipe.getTime()) + "분";

        // 3-3. Post 엔티티 생성
        Post newPost = Post.builder()
                .user(user)
                .title(originalRecipe.getTitle())         // Recipe.title -> Post.title
                .content(originalRecipe.getInstructions()) // Recipe.instructions -> Post.content
                .cookTime(cookTimeString)                 // Recipe.time -> Post.cookTime
                .ingredients(ingredientsString)           // Recipe.recipeIngredients -> Post.ingredients
                .imageUrl(originalRecipe.getImageUrl())   // Recipe.imageUrl -> Post.imageUrl
                .build();

        // 4. 'Post' 게시글로 DB에 저장
        Post savedPost = postRepository.save(newPost);

        // 5. 저장된 Post 정보를 DTO로 변환하여 반환
        return new PostResponseDto(savedPost);
    }
    // --- ⬇️ '게시글 상세 조회 (READ ONE)' 메서드 추가 ⬇️ ---

    /**
     * 게시글 1건 상세 조회 (READ)
     * @param postId 조회할 게시글 ID
     * @return 게시글 상세 정보 DTO
     */
    @Transactional(readOnly = true) // (1) 읽기 전용 트랜잭션 (성능 향상)
    public PostResponseDto getPost(Long postId) {

        // 1. Repository에서 postId로 Post 엔티티를 찾음
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new IllegalArgumentException("해당 게시글을 찾을 수 없습니다. id=" + postId));

        // 2. 찾아온 Post 엔티티를 PostResponseDto로 변환하여 반환
        return new PostResponseDto(post);
    }
    /**
     * 게시글 전체 목록 조회 (최신순)
     * @return 게시글 목록 DTO 리스트
     */
    @Transactional(readOnly = true)
    public List<PostListResponseDto> getAllPosts() {

        // OLD: List<Post> posts = postRepository.findAll(Sort.by(Sort.Direction.DESC, "createdAt"));

        // ⬇️ [수정] 새로 만든 findAllWithDetails 메서드를 호출합니다. ⬇️
        List<Post> posts = postRepository.findAllWithDetails(Sort.by(Sort.Direction.DESC, "createdAt"));

        // 2. Post 엔티티 List를 -> PostListResponseDto List로 변환
        return posts.stream()
                .map(PostListResponseDto::new)
                .collect(Collectors.toList());
    }
    @Transactional // (1) 데이터를 변경하므로 readOnly = false (기본값)
    public PostResponseDto updatePost(Long postId, PostUpdateRequestDto requestDto, Long userId) {

        // 1. Repository에서 postId로 Post 엔티티를 찾음
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new IllegalArgumentException("해당 게시글을 찾을 수 없습니다. id=" + postId));

        // 2. (중요) 본인 확인
        //    게시글 작성자(post.getUser().getId())와
        //    현재 로그인한 사용자(userId)가 같은지 확인
        if (!post.getUser().getId().equals(userId)) {
            // (SecurityException 대신 적절한 예외 처리를 해주세요)
            throw new SecurityException("게시글을 수정할 권한이 없습니다.");
        }

        // 3. Post 엔티티에 만들어둔 update 메서드를 호출하여 내용 변경
        //    (JPA가 트랜잭션 종료 시 변경된 내용을 감지하여 DB에 자동 반영)
        post.update(
                requestDto.getTitle(),
                requestDto.getContent(),
                requestDto.getCookTime(),
                requestDto.getIngredients(),
                requestDto.getImageUrl()
        );

        // 4. 변경된 엔티티를 DTO로 변환하여 반환
        return new PostResponseDto(post);
    }
    /**
     * 게시글 삭제 (DELETE)
     * @param postId 삭제할 게시글 ID
     * @param userId (JWT 토큰에서 추출한) 사용자 ID
     */
    @Transactional
    public void deletePost(Long postId, Long userId) {

        // 1. Repository에서 postId로 Post 엔티티를 찾음
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new IllegalArgumentException("해당 게시글을 찾을 수 없습니다. id=" + postId));

        // 2. (중요) 본인 확인
        if (!post.getUser().getId().equals(userId)) {
            throw new SecurityException("게시글을 삭제할 권한이 없습니다.");
        }

        // 3. (삭제) Repository의 delete 메서드 호출
        //    (CascadeType.ALL 설정 덕분에 이 게시글에 달린
        //     Like, Dislike, Review도 함께 삭제됩니다.)
        postRepository.delete(post);
    }

    // (여기에 앞으로 getAllPosts, updatePost 등이 추가됩니다)
}