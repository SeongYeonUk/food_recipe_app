package cau.team_refrigerator.refrigerator.controller;

import cau.team_refrigerator.refrigerator.domain.Item;
import cau.team_refrigerator.refrigerator.domain.Refrigerator;
import cau.team_refrigerator.refrigerator.domain.User;
import cau.team_refrigerator.refrigerator.domain.dto.NotificationPreferenceDto;
import cau.team_refrigerator.refrigerator.domain.dto.RecipeDetailResponseDto;
import cau.team_refrigerator.refrigerator.domain.DeviceToken;
import cau.team_refrigerator.refrigerator.domain.NotificationLog;
import cau.team_refrigerator.refrigerator.repository.ItemRepository;
import cau.team_refrigerator.refrigerator.repository.RefrigeratorRepository;
import cau.team_refrigerator.refrigerator.repository.UserRepository;
import cau.team_refrigerator.refrigerator.repository.DeviceTokenRepository;
import cau.team_refrigerator.refrigerator.repository.NotificationLogRepository;
import cau.team_refrigerator.refrigerator.service.NotificationPreferenceService;
import cau.team_refrigerator.refrigerator.service.RecipeService;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/notifications")
public class NotificationController {

    private final NotificationPreferenceService preferenceService;
    private final UserRepository userRepository;
    private final RefrigeratorRepository refrigeratorRepository;
    private final ItemRepository itemRepository;
    private final RecipeService recipeService;
    private final DeviceTokenRepository deviceTokenRepository;
    private final NotificationLogRepository notificationLogRepository;

    private User getCurrentUser(UserDetails userDetails) {
        String uid = userDetails.getUsername();
        return userRepository.findByUid(uid)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다. UID: " + uid));
    }

    @GetMapping("/prefs")
    public ResponseEntity<NotificationPreferenceDto> getPrefs(@AuthenticationPrincipal UserDetails userDetails) {
        User currentUser = getCurrentUser(userDetails);
        return ResponseEntity.ok(NotificationPreferenceDto.from(preferenceService.getOrCreate(currentUser)));
    }

    @PutMapping("/prefs")
    public ResponseEntity<NotificationPreferenceDto> updatePrefs(
            @RequestBody UpdatePrefRequest req,
            @AuthenticationPrincipal UserDetails userDetails) {
        User currentUser = getCurrentUser(userDetails);
        var updated = preferenceService.update(currentUser, req.getNotifyHour(), req.getNotifyMinute(), req.getEnabled(), req.getHomeOnly());
        return ResponseEntity.ok(NotificationPreferenceDto.from(updated));
    }

    @GetMapping("/preview")
    public ResponseEntity<NotificationPreviewResponse> preview(@AuthenticationPrincipal UserDetails userDetails) {
        User currentUser = getCurrentUser(userDetails);

        // Aggregate expiring items (3 and 7 days)
        int danger3 = 0;
        int caution7 = 0;
        LocalDate today = LocalDate.now();
        List<Refrigerator> fridges = refrigeratorRepository.findAllByUser(currentUser);
        for (Refrigerator fridge : fridges) {
            List<Item> items = itemRepository.findAllByRefrigeratorId(fridge.getId());
            for (Item it : items) {
                if (it.getExpiryDate() == null) continue;
                long days = ChronoUnit.DAYS.between(today, it.getExpiryDate());
                if (days == 3) danger3++;
                if (days == 7) caution7++;
            }
        }

        // Top recipe suggestion: first from recommendations
        List<RecipeDetailResponseDto> recs = recipeService.recommendRecipes(currentUser);
        RecipeSummary top = null;
        if (recs != null && !recs.isEmpty()) {
            var r = recs.get(0);
            top = new RecipeSummary(r.getRecipeId(), r.getRecipeName(), r.getImageUrl());
        }

        NotificationPreviewResponse resp = new NotificationPreviewResponse(
                new IngredientSummary(caution7, danger3),
                top
        );
        return ResponseEntity.ok(resp);
    }

    @PostMapping("/token")
    public ResponseEntity<String> registerToken(@RequestBody RegisterTokenRequest req,
                                                @AuthenticationPrincipal UserDetails userDetails) {
        User currentUser = getCurrentUser(userDetails);
        var existing = deviceTokenRepository.findByToken(req.getToken());
        if (existing.isEmpty()) {
            deviceTokenRepository.save(new DeviceToken(currentUser, req.getToken(), req.getPlatform() == null ? "ANDROID" : req.getPlatform()));
        }
        return ResponseEntity.ok("registered");
    }

    @DeleteMapping("/token")
    public ResponseEntity<String> deleteToken(@RequestParam("token") String token,
                                              @AuthenticationPrincipal UserDetails userDetails) {
        deviceTokenRepository.findByToken(token).ifPresent(deviceTokenRepository::delete);
        return ResponseEntity.ok("deleted");
    }

    @GetMapping
    public ResponseEntity<List<NotificationLogDto>> history(@AuthenticationPrincipal UserDetails userDetails) {
        User currentUser = getCurrentUser(userDetails);
        var logs = notificationLogRepository.findAllByUserOrderBySentAtDesc(currentUser);
        return ResponseEntity.ok(logs.stream()
                .map(NotificationLogDto::from)
                .collect(Collectors.toList()));
    }

    // DTOs
    @Getter @Setter
    public static class UpdatePrefRequest {
        private Integer notifyHour; // 0-23
        private Integer notifyMinute; // 0-59
        private Boolean enabled;
        private Boolean homeOnly;
    }

    @Getter @Setter
    public static class RegisterTokenRequest {
        private String token;
        private String platform; // ANDROID / IOS
    }

    @Getter
    public static class IngredientSummary {
        private final int caution7; // 7 days
        private final int danger3;  // 3 days
        public IngredientSummary(int caution7, int danger3) {
            this.caution7 = caution7;
            this.danger3 = danger3;
        }
    }

    @Getter
    public static class RecipeSummary {
        private final Long id;
        private final String name;
        private final String imageUrl;
        public RecipeSummary(Long id, String name, String imageUrl) {
            this.id = id;
            this.name = name;
            this.imageUrl = imageUrl;
        }
    }

    @Getter
    public static class NotificationPreviewResponse {
        private final IngredientSummary ingredient;
        private final RecipeSummary recipe;
        public NotificationPreviewResponse(IngredientSummary ingredient, RecipeSummary recipe) {
            this.ingredient = ingredient;
            this.recipe = recipe;
        }
    }

    @Getter
    public static class NotificationLogDto {
        private final String type;
        private final String title;
        private final String body;
        private final Date sentAt;
        public NotificationLogDto(String type, String title, String body, Date sentAt) {
            this.type = type; this.title = title; this.body = body; this.sentAt = sentAt;
        }
        public static NotificationLogDto from(NotificationLog log) {
            return new NotificationLogDto(log.getType(), log.getTitle(), log.getBody(),
                    log.getSentAt() != null ? java.sql.Timestamp.valueOf(log.getSentAt()) : null);
        }
    }

    // For client-side testing: let app write a log entry after showing local notifications
    @PostMapping("/log")
    public ResponseEntity<String> logEntry(@RequestBody LogRequest req,
                                           @AuthenticationPrincipal UserDetails userDetails) {
        User currentUser = getCurrentUser(userDetails);
        NotificationLog log = new NotificationLog(
                currentUser,
                req.getType() == null ? "MISC" : req.getType(),
                req.getTitle() == null ? "" : req.getTitle(),
                req.getBody(),
                LocalDate.now(),
                "SENT"
        );
        notificationLogRepository.save(log);
        return ResponseEntity.ok("logged");
    }

    @Getter @Setter
    public static class LogRequest {
        private String type; // INGREDIENT / RECIPE / etc
        private String title;
        private String body;
    }
}
