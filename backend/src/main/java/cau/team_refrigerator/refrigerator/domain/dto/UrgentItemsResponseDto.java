package cau.team_refrigerator.refrigerator.domain.dto;

import cau.team_refrigerator.refrigerator.domain.Item;
import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

@Getter
@AllArgsConstructor
public class UrgentItemsResponseDto {
    private List<UrgentItemDto> items;

    public static UrgentItemsResponseDto fromItems(List<Item> items) {
        List<UrgentItemDto> dtoList = items.stream()
                .map(i -> new UrgentItemDto(i.getName(), i.getExpiryDate(), i.getQuantity()))
                .collect(Collectors.toList());
        return new UrgentItemsResponseDto(dtoList);
    }

    @Getter
    @AllArgsConstructor
    public static class UrgentItemDto {
        private String name;
        private LocalDate expiryDate;
        private int quantity;
    }
}
