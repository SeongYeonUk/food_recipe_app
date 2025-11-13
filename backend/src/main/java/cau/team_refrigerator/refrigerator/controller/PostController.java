package cau.team_refrigerator.refrigerator.controller;

import cau.team_refrigerator.refrigerator.domain.dto.PostListResponseDto;
import cau.team_refrigerator.refrigerator.domain.dto.PostResponseDto;
import cau.team_refrigerator.refrigerator.domain.dto.PostShareRequestDto;
import cau.team_refrigerator.refrigerator.domain.dto.PostUpdateRequestDto;
import cau.team_refrigerator.refrigerator.service.PostService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;


import java.util.List;

@RestController // (1) 이 클래스가 REST API 컨트롤러임을 선언
@RequiredArgsConstructor // (2) final PostService 생성자 자동 주입
@RequestMapping("/api/posts") // (3) 이 컨트롤러의 모든 API는 /api/posts 로 시작
public class PostController {

    private final PostService postService;

    /**
     * '나만의 레시피' -> '레시피 자랑'으로 공유 (생성)
     * [POST /api/posts/share]
     */
    @PostMapping("/share") // (4) HTTP POST 메서드, /api/posts/share 주소에 매핑
    public ResponseEntity<PostResponseDto> shareRecipeAsPost(
            @RequestBody PostShareRequestDto requestDto // (5) HTTP Body에 담겨온 JSON을 DTO로 변환
            // (TODO) JWT 토큰에서 사용자 ID를 추출하는 로직 필요
    ) {
        // (6) TODO: 여기에 JWT 토큰을 검증하고 사용자 ID(Long userId)를 가져오는 코드가 필요합니다.
        // 예시: Long currentUserId = jwtTokenProvider.getUserIdFromToken(token);
        // 지금은 임시로 1L을 사용하겠습니다. 이 부분은 반드시 실제 유저 ID로 교체해야 합니다!
        Long currentUserId = 1L; // 🚨 (임시) 실제 유저 ID로 변경 필요

        // (7) 서비스 호출
        PostResponseDto responseDto = postService.shareRecipeAsPost(requestDto, currentUserId);

        // (8) 생성 완료 응답 (HTTP Status 201 Created)
        return ResponseEntity.status(HttpStatus.CREATED).body(responseDto);
    }

    /**
     * 게시글 1건 상세 조회
     * [GET /api/posts/{postId}]
     */
    @GetMapping("/{postId}") // (1) HTTP GET 메서드, /api/posts/1, /api/posts/2 ...
    public ResponseEntity<PostResponseDto> getPostById(
            @PathVariable Long postId // (2) URL 경로({postId})에서 값을 추출
    ) {
        // (3) 서비스 호출
        PostResponseDto responseDto = postService.getPost(postId);

        // (4) 조회 성공 응답 (HTTP Status 200 OK)
        return ResponseEntity.ok(responseDto);
    }
    // --- ⬇️ '게시글 전체 목록 조회' API 추가 ⬇️ ---

    /**
     * 게시글 전체 목록 조회
     * [GET /api/posts]
     */
    @GetMapping // (1) HTTP GET 메서드, /api/posts 주소에 매핑
    public ResponseEntity<List<PostListResponseDto>> getAllPosts() {

        List<PostListResponseDto> responseDtoList = postService.getAllPosts();

        // (2) 조회 성공 (HTTP 200 OK)
        return ResponseEntity.ok(responseDtoList);
    }
    @PutMapping("/{postId}") // (1) HTTP PUT 메서드, /api/posts/1 ...
    public ResponseEntity<PostResponseDto> updatePost(
            @PathVariable Long postId, // (2) URL에서 수정할 ID 추출
            @RequestBody PostUpdateRequestDto requestDto // (3) HTTP Body에서 수정할 내용 추출
            // (TODO) JWT 토큰에서 사용자 ID 추출
    ) {
        // (4) TODO: 여기에 JWT 토큰을 검증하고 사용자 ID(Long userId)를 가져오는 코드가 필요합니다.
        Long currentUserId = 1L; // 🚨 (임시) 실제 유저 ID로 변경 필요

        // (5) 서비스 호출 (본인 확인은 Service에서 수행)
        PostResponseDto responseDto = postService.updatePost(postId, requestDto, currentUserId);

        // (6) 수정 성공 응답 (HTTP 200 OK)
        return ResponseEntity.ok(responseDto);
    }
    @DeleteMapping("/{postId}") // (1) HTTP DELETE 메서드, /api/posts/1 ...
    public ResponseEntity<Void> deletePost(
            @PathVariable Long postId // (2) URL에서 삭제할 ID 추출
            // (TODO) JWT 토큰에서 사용자 ID 추출
    ) {
        // (3) TODO: 여기에 JWT 토큰을 검증하고 사용자 ID(Long userId)를 가져오는 코드가 필요합니다.
        Long currentUserId = 1L; // 🚨 (임시) 실제 유저 ID로 변경 필요

        // (4) 서비스 호출 (본인 확인은 Service에서 수행)
        postService.deletePost(postId, currentUserId);

        // (5) 삭제 성공 응답 (HTTP 204 No Content)
        return ResponseEntity.noContent().build();
    }

}