package cau.team_refrigerator.refrigerator.domain.dto;

import cau.team_refrigerator.refrigerator.domain.ItemCategory;
import lombok.Getter;
import java.time.LocalDate;

@Getter
public class ItemCreateRequestDto {
    private String name;
    private int quantity;
    private LocalDate expiryDate;
    private LocalDate registrationDate;
    private ItemCategory category;
    private int iconIndex; // new: per-item icon index
}
