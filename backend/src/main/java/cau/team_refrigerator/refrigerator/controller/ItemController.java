package cau.team_refrigerator.refrigerator.controller;

import cau.team_refrigerator.refrigerator.domain.dto.ItemCreateRequestDto;
import cau.team_refrigerator.refrigerator.domain.dto.ItemResponseDto;
import cau.team_refrigerator.refrigerator.domain.dto.ItemUpdateRequestDto;
import cau.team_refrigerator.refrigerator.service.ItemService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.Map;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api")
public class ItemController {

    private final ItemService itemService;

    // 식재료 추가 API
    @PostMapping("/refrigerators/{refrigeratorId}/items")
    public ResponseEntity<Map<String, Object>> createItem(
            @PathVariable Long refrigeratorId,
            @RequestBody ItemCreateRequestDto requestDto,
            Principal principal
    ) {
        // principal.getName()으로 사용자 ID를 서비스에 전달
        Long newItemId = itemService.createItem(principal.getName(), refrigeratorId, requestDto);

        Map<String, Object> response = Map.of("itemId", newItemId, "message", "성공적으로 추가되었습니다.");
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    // 냉장고 식재료 조회 API
    @GetMapping("/refrigerators/{refrigeratorId}/items")
    public ResponseEntity<List<ItemResponseDto>> getItemsInRefrigerator(
            @PathVariable Long refrigeratorId,
            Principal principal // <-- [수정] Principal 추가
    ) {
        // principal.getName()으로 사용자 ID를 서비스에 전달
        List<ItemResponseDto> items = itemService.findItemsByRefrigerator(principal.getName(), refrigeratorId);
        return ResponseEntity.ok(items);
    }

    // 식재료 수정 API
    @PutMapping("/items/{itemId}")
    public ResponseEntity<String> updateItem(
            @PathVariable Long itemId,
            @RequestBody ItemUpdateRequestDto requestDto,
            Principal principal
    ) {
        itemService.updateItem(principal.getName(), itemId, requestDto);
        return ResponseEntity.ok("성공적으로 수정되었습니다.");
    }

    // 식재료 삭제 API
    @DeleteMapping("/items/{itemId}")
    public ResponseEntity<String> deleteItem(@PathVariable Long itemId, Principal principal) {
        itemService.deleteItem(principal.getName(), itemId);
        return ResponseEntity.ok("성공적으로 삭제되었습니다.");
    }
}