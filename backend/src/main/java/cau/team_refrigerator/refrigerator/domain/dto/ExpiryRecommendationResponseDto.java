package cau.team_refrigerator.refrigerator.domain.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ExpiryRecommendationResponseDto {
    private List<ExpiryItem> recommendations;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ExpiryItem {
        private String name;
        private String recommendedDate;
        private boolean updated;
    }
}
