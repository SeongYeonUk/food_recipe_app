package cau.team_refrigerator.refrigerator.controller;

import cau.team_refrigerator.refrigerator.domain.ItemCategory;
import cau.team_refrigerator.refrigerator.domain.Refrigerator;
import cau.team_refrigerator.refrigerator.domain.RefrigeratorType;
import cau.team_refrigerator.refrigerator.domain.User;
import cau.team_refrigerator.refrigerator.domain.dto.ItemCreateRequestDto; // DTO import 확인
import cau.team_refrigerator.refrigerator.domain.dto.RefrigeratorResponseDto;
import cau.team_refrigerator.refrigerator.repository.RefrigeratorRepository;
import cau.team_refrigerator.refrigerator.repository.UserRepository;
import cau.team_refrigerator.refrigerator.service.RefrigeratorService;
import cau.team_refrigerator.refrigerator.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/refrigerators") // ✅ 기존 코드 유지 (복수형)
@RequiredArgsConstructor
public class RefrigeratorController {

    private final RefrigeratorRepository refrigeratorRepository;
    private final UserService userService;

    // 👇 [추가] 재료 추가 로직을 위해 필요한 서비스와 레포지토리
    private final RefrigeratorService refrigeratorService;
    private final UserRepository userRepository;

    // 1. 내 냉장고 목록 조회 (기존 코드 유지)
    @GetMapping
    public ResponseEntity<List<RefrigeratorResponseDto>> getMyRefrigerators(Principal principal) {
        User currentUser = userService.getUserById(principal.getName());
        List<Refrigerator> refrigerators = refrigeratorRepository.findAllByUser(currentUser);
        List<RefrigeratorResponseDto> dtoList = refrigerators.stream()
                .map(RefrigeratorResponseDto::new)
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtoList);
    }

    // 2. [신규 추가] 재료 추가 (GPT 자동 날짜 연동)
    // URL: /api/refrigerators/add
    @PostMapping("/add")
    public ResponseEntity<String> addIngredient(
            @RequestBody ItemCreateRequestDto request,
            Principal principal
    ) {
        User user = userRepository.findByUid(principal.getName())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        // 🛠️ [수정 포인트] DTO가 이미 타입을 잘 가지고 있어서 변환할 필요가 없습니다!
        refrigeratorService.addIngredient(
                request.getName(),
                request.getExpiryDate(), // 이미 LocalDate임 (null이면 서비스가 GPT 호출)
                request.getQuantity(),
                request.getCategory(),   // 이미 ItemCategory Enum임
                user,
                RefrigeratorType.valueOf(request.getRefrigeratorType()) // String -> Enum 변환
        );

        return ResponseEntity.ok("재료가 성공적으로 추가되었습니다.");
    }
}