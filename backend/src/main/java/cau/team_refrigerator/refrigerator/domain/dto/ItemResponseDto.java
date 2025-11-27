package cau.team_refrigerator.refrigerator.domain.dto;

import cau.team_refrigerator.refrigerator.domain.ItemCategory;
import cau.team_refrigerator.refrigerator.domain.Item;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Getter
@Builder
@AllArgsConstructor // 👈 Builder 사용 시 필수!
@NoArgsConstructor  // 👈 JSON 변환 시 필수!
public class ItemResponseDto {
    private Long id;
    private String name;
    private int quantity;

    // ⚠️ [수정] LocalDate -> String (GPT가 준 문자열 "2025-11-30"을 그대로 담기 위해)
    private String expiryDate;

    private LocalDate registrationDate;
    private ItemCategory category;
    private int iconIndex;

    // 👇 [추가] 바코드/OCR 서비스에서 이미지 URL을 담기 위해 추가
    private String imageUrl;

    // 기존 생성자 유지 (Item 엔티티 -> DTO 변환용)
    public ItemResponseDto(Item item) {
        this.id = item.getId();
        this.name = item.getName();
        this.quantity = item.getQuantity();
        // DB에 있는 LocalDate를 String으로 변환해서 저장
        this.expiryDate = item.getExpiryDate() != null ? item.getExpiryDate().toString() : null;
        this.registrationDate = item.getRegistrationDate();
        this.category = item.getCategory();
        this.iconIndex = item.getIconIndex();
        this.imageUrl = null; // 엔티티에서 가져올 이미지가 없다면 null 처리
    }
}