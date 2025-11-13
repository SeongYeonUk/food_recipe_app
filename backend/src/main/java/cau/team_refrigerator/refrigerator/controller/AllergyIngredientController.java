package cau.team_refrigerator.refrigerator.controller;

import cau.team_refrigerator.refrigerator.domain.User;
import cau.team_refrigerator.refrigerator.domain.dto.AllergyIngredientRequestDto;
import cau.team_refrigerator.refrigerator.domain.dto.AllergyIngredientResponseDto;
import cau.team_refrigerator.refrigerator.repository.UserRepository;
import cau.team_refrigerator.refrigerator.service.AllergyIngredientService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/allergies")
@RequiredArgsConstructor
public class AllergyIngredientController {

    private final AllergyIngredientService allergyIngredientService;
    private final UserRepository userRepository;

    @GetMapping
    public ResponseEntity<List<AllergyIngredientResponseDto>> getAll(
            @AuthenticationPrincipal UserDetails userDetails
    ) {
        User currentUser = findCurrentUser(userDetails);
        return ResponseEntity.ok(allergyIngredientService.getAll(currentUser));
    }

    @PostMapping
    public ResponseEntity<AllergyIngredientResponseDto> add(
            @RequestBody AllergyIngredientRequestDto requestDto,
            @AuthenticationPrincipal UserDetails userDetails
    ) {
        User currentUser = findCurrentUser(userDetails);
        return ResponseEntity.ok(allergyIngredientService.add(currentUser, requestDto));
    }

    @DeleteMapping("/{allergyId}")
    public ResponseEntity<Void> delete(
            @PathVariable Long allergyId,
            @AuthenticationPrincipal UserDetails userDetails
    ) {
        User currentUser = findCurrentUser(userDetails);
        allergyIngredientService.delete(currentUser, allergyId);
        return ResponseEntity.noContent().build();
    }

    private User findCurrentUser(UserDetails userDetails) {
        String uid = userDetails.getUsername();
        return userRepository.findByUid(uid)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다. UID: " + uid));
    }
}
