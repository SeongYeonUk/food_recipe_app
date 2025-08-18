package cau.team_refrigerator.refrigerator.controller;

import cau.team_refrigerator.refrigerator.domain.dto.ItemCreateRequestDto;
import cau.team_refrigerator.refrigerator.domain.dto.ItemResponseDto;
import cau.team_refrigerator.refrigerator.domain.dto.ItemUpdateRequestDto;
import cau.team_refrigerator.refrigerator.service.ItemService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api")
public class ItemController {

    private final ItemService itemService;

    // 1. 식재료 추가 API
    @PostMapping("/refrigerators/{refrigeratorId}/items")
    public ResponseEntity<Map<String, Object>> createItem(@PathVariable Long refrigeratorId, @RequestBody ItemCreateRequestDto requestDto) {

        Long newItemId = itemService.createItem(refrigeratorId, requestDto);

        Map<String, Object> response = Map.of("itemId", newItemId, "message", "성공적으로 추가되었습니다.");

        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    // 2. 특정 냉장고 식재료 조회 API
    @GetMapping("/refrigerators/{refrigeratorId}/items")
    public ResponseEntity<List<ItemResponseDto>> getItemsInRefrigerator(@PathVariable Long refrigeratorId)
    {
        List<ItemResponseDto> items = itemService.findItemsByRefrigerator(refrigeratorId);
        return ResponseEntity.ok(items);
    }
    // 3. 식재료 수정 API
    @PutMapping("/refrigerators/{refrigeratorId}/items/{itemId}")
    public ResponseEntity<String> updateItem(@PathVariable Long refrigeratorId, @PathVariable Long itemId, @RequestBody ItemUpdateRequestDto requestDto)
    {
        itemService.updateItem(itemId, requestDto);
        return ResponseEntity.ok("성공적으로 수정되었습니다.");
    }

    /**
     * 4. 식재료 삭제 API
     */
    @DeleteMapping("/refrigerators/{refrigeratorId}/items/{itemId}")
    public ResponseEntity<String> deleteItem(@PathVariable Long refrigeratorId, @PathVariable Long itemId)
    {
        itemService.deleteItem(itemId);
        return ResponseEntity.ok("성공적으로 삭제되었습니다.");
    }

}
