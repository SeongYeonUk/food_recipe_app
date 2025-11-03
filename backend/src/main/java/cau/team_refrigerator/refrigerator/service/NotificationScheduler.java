package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.domain.*;
import cau.team_refrigerator.refrigerator.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;

@Component
@RequiredArgsConstructor
public class NotificationScheduler {

    private final NotificationPreferenceRepository prefRepo;
    private final UserRepository userRepository;
    private final RefrigeratorRepository refrigeratorRepository;
    private final ItemRepository itemRepository;
    private final RecipeService recipeService;
    private final DeviceTokenRepository deviceTokenRepository;
    private final NotificationLogRepository logRepository;
    private final PushNotificationService pushService;

    private final ZoneId zone = ZoneId.of("Asia/Seoul");

    // Every 5 minutes
    @Scheduled(cron = "0 */5 * * * *")
    public void run() {
        LocalDateTime now = LocalDateTime.now(zone);
        LocalDate today = now.toLocalDate();

        var prefs = prefRepo.findAll();
        for (NotificationPreference p : prefs) {
            if (!p.isEnabled()) continue;

            // Time window ±5 minutes
            if (!isWithinWindow(now.getHour(), now.getMinute(), p.getNotifyHour(), p.getNotifyMinute(), 5)) {
                continue;
            }

            // Daily de-dup: if already sent for today, skip
            User user = p.getUser();
            boolean ingDone = logRepository.existsByUserAndTypeAndScheduledFor(user, "INGREDIENT", today);
            boolean recDone = logRepository.existsByUserAndTypeAndScheduledFor(user, "RECIPE", today);

            List<DeviceToken> tokens = deviceTokenRepository.findAllByUser(user);
            if (tokens.isEmpty()) continue;

            // Ingredient summary
            if (!ingDone) {
                int caution7 = 0; int danger3 = 0;
                var fridges = refrigeratorRepository.findAllByUser(user);
                for (Refrigerator f : fridges) {
                    var items = itemRepository.findAllByRefrigeratorId(f.getId());
                    for (Item it : items) {
                        if (it.getExpiryDate() == null) continue;
                        long days = ChronoUnit.DAYS.between(today, it.getExpiryDate());
                        if (days == 7) caution7++;
                        if (days == 3) danger3++;
                    }
                }
                if (caution7 > 0 || danger3 > 0) {
                    var title = "식재료 유통기한 알림";
                    List<String> parts = new ArrayList<>();
                    if (danger3 > 0) parts.add("위험 3일 이내: " + danger3 + "개");
                    if (caution7 > 0) parts.add("주의 7일 이내: " + caution7 + "개");
                    var body = String.join(" · ", parts);
                    var log = new NotificationLog(user, "INGREDIENT", title, body, today, "PENDING");
                    logRepository.save(log);
                    pushService.sendToTokens(tokens, title, body);
                    log.markSent();
                    logRepository.save(log);
                }
            }

            // Recipe recommendation
            if (!recDone) {
                var recs = recipeService.recommendRecipes(user);
                if (recs != null && !recs.isEmpty()) {
                    var top = recs.get(0);
                    var title = "오늘의 추천 레시피";
                    var body = top.getRecipeName();
                    var log = new NotificationLog(user, "RECIPE", title, body, today, "PENDING");
                    logRepository.save(log);
                    pushService.sendToTokens(tokens, title, body);
                    log.markSent();
                    logRepository.save(log);
                }
            }
        }
    }

    private boolean isWithinWindow(int nowH, int nowM, int targetH, int targetM, int windowMinutes) {
        int nowTotal = nowH * 60 + nowM;
        int targetTotal = targetH * 60 + targetM;
        return Math.abs(nowTotal - targetTotal) <= windowMinutes;
    }
}

