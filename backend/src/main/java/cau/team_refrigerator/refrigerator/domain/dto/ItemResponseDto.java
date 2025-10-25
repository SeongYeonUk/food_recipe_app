package cau.team_refrigerator.refrigerator.domain.dto;

import cau.team_refrigerator.refrigerator.domain.ItemCategory;
import cau.team_refrigerator.refrigerator.domain.Item;
import lombok.Getter;
import java.time.LocalDate;

@Getter
public class ItemResponseDto {
    private final Long id;
    private final String name;
    private final int quantity;
    private final LocalDate expiryDate;
    private final LocalDate registrationDate;
    private final ItemCategory category;

    public ItemResponseDto(Item item) {
        this.id = item.getId();
        this.name = item.getName();
        this.quantity = item.getQuantity();
        this.expiryDate = item.getExpiryDate();
        this.registrationDate = item.getRegistrationDate();
        this.category = item.getCategory();
    }
}