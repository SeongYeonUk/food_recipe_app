package cau.team_refrigerator.refrigerator.domain.dto;

import lombok.Builder;
import lombok.Data;
import java.util.List;

@Data
@Builder
public class ChatbotInventoryResponseDto {
    // 1. 음성 출력용 (예: "지금 냉장고에 계란, 양파 있어.")
    private String message;

    // 2. 화면 출력용 상세 리스트
    private List<ItemDetailDto> items;

    @Data
    @Builder
    public static class ItemDetailDto {
        private String name;       // 재료명
        private String expiryDate; // 유통기한
        private int quantity;      // 용량
        private String dDay;       // (옵션) D-3, D-Day 등
    }
}