package cau.team_refrigerator.refrigerator.domain.dto;

import cau.team_refrigerator.refrigerator.domain.NotificationPreference;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
@AllArgsConstructor
public class NotificationPreferenceDto {
    private int notifyHour;
    private int notifyMinute;
    private boolean enabled;
    private boolean homeOnly;

    public static NotificationPreferenceDto from(NotificationPreference pref) {
        return new NotificationPreferenceDto(
                pref.getNotifyHour(),
                pref.getNotifyMinute(),
                pref.isEnabled(),
                pref.isHomeOnly()
        );
    }
}

