package cau.team_refrigerator.refrigerator.domain.dto;

import cau.team_refrigerator.refrigerator.domain.ItemCategory;
import lombok.Getter;
import lombok.NoArgsConstructor;
import java.time.LocalDate;

@Getter
@NoArgsConstructor
public class ItemUpdateRequestDto
{
    private String name;
    private LocalDate expiryDate;
    private int quantity;
    private ItemCategory category;
}