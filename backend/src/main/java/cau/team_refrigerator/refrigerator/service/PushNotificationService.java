package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.domain.DeviceToken;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class PushNotificationService {

    @Value("${fcm.server-key:}")
    private String fcmServerKey;

    private final RestTemplate restTemplate = new RestTemplate();

    public void sendToTokens(List<DeviceToken> tokens, String title, String body) {
        if (tokens == null || tokens.isEmpty()) return;
        if (fcmServerKey == null || fcmServerKey.isBlank()) {
            // Fallback: no server key configured
            return;
        }

        for (DeviceToken t : tokens) {
            Map<String, Object> payload = new HashMap<>();
            payload.put("to", t.getToken());
            Map<String, String> notification = new HashMap<>();
            notification.put("title", title);
            notification.put("body", body);
            payload.put("notification", notification);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("Authorization", "key=" + fcmServerKey);
            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(payload, headers);
            try {
                restTemplate.postForEntity("https://fcm.googleapis.com/fcm/send", entity, String.class);
            } catch (Exception ignored) { }
        }
    }
}

