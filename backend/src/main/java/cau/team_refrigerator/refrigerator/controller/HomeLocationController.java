package cau.team_refrigerator.refrigerator.controller;

import cau.team_refrigerator.refrigerator.domain.User;
import cau.team_refrigerator.refrigerator.domain.HomeLocation;
import cau.team_refrigerator.refrigerator.domain.dto.HomeLocationDto;
import cau.team_refrigerator.refrigerator.repository.UserRepository;
import cau.team_refrigerator.refrigerator.service.HomeLocationService;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.Optional;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/location")
public class HomeLocationController {

    private final HomeLocationService homeLocationService;
    private final UserRepository userRepository;

    private User current(UserDetails ud) {
        return userRepository.findByUid(ud.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
    }

    @GetMapping("/home")
    public ResponseEntity<?> getHome(@AuthenticationPrincipal UserDetails userDetails) {
        User user = current(userDetails);
        Optional<HomeLocation> hl = homeLocationService.find(user);
        return hl.<ResponseEntity<?>>map(home -> ResponseEntity.ok(HomeLocationDto.from(home)))
                .orElseGet(() -> ResponseEntity.noContent().build());
    }

    @PutMapping("/home")
    public ResponseEntity<HomeLocationDto> setHome(@RequestBody UpsertHomeRequest req,
                                                   @AuthenticationPrincipal UserDetails userDetails) {
        User user = current(userDetails);
        HomeLocation updated = homeLocationService.upsert(user, req.getLatitude(), req.getLongitude(), req.getRadiusMeters());
        return ResponseEntity.ok(HomeLocationDto.from(updated));
    }

    @Getter @Setter
    public static class UpsertHomeRequest {
        private double latitude;
        private double longitude;
        private Integer radiusMeters; // optional, default 100
    }
}

