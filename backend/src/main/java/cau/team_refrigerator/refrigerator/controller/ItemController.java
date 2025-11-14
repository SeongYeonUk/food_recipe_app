package cau.team_refrigerator.refrigerator.controller;

import cau.team_refrigerator.refrigerator.domain.dto.ItemCreateRequestDto;
import cau.team_refrigerator.refrigerator.domain.dto.ItemResponseDto;
import cau.team_refrigerator.refrigerator.domain.dto.ItemUpdateRequestDto;
import cau.team_refrigerator.refrigerator.service.ItemService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import cau.team_refrigerator.refrigerator.service.SttService;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.bind.annotation.RequestBody;
import java.io.IOException;

import java.security.Principal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class ItemController {

    private final ItemService itemService;
    private final SttService sttService; // 새로 추가

    // 생성자 수정
    public ItemController(ItemService itemService, SttService sttService) {
        this.itemService = itemService;
        this.sttService = sttService;
    }

    // 식재료 추가 API
    @PostMapping("/refrigerators/{refrigeratorId}/items")
    public ResponseEntity<Map<String, Object>> createItem(
            @PathVariable("refrigeratorId") Long refrigeratorId, // [수정] ("refrigeratorId") 추가
            @RequestBody ItemCreateRequestDto requestDto,
            Principal principal
    ) {
        Long newItemId = itemService.createItem(principal.getName(), refrigeratorId, requestDto);
        Map<String, Object> response = new HashMap<>();
        response.put("itemId", newItemId);
        response.put("message", "성공적으로 추가되었습니다.");
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    // 냉장고 식재료 조회 API
    @GetMapping("/refrigerators/{refrigeratorId}/items")
    public ResponseEntity<List<ItemResponseDto>> getItemsInRefrigerator(
            @PathVariable("refrigeratorId") Long refrigeratorId, // [수정] ("refrigeratorId") 추가
            Principal principal
    ) {
        List<ItemResponseDto> items = itemService.findItemsByRefrigerator(principal.getName(), refrigeratorId);
        return ResponseEntity.ok(items);
    }

    // 식재료 수정 API
    @PutMapping("/items/{itemId}")
    public ResponseEntity<String> updateItem(
            @PathVariable("itemId") Long itemId, // [수정] ("itemId") 추가
            @RequestBody ItemUpdateRequestDto requestDto,
            Principal principal
    ) {
        itemService.updateItem(principal.getName(), itemId, requestDto);
        return ResponseEntity.ok("성공적으로 수정되었습니다.");
    }

    // 식재료 삭제 API
    @DeleteMapping("/items/{itemId}")
    public ResponseEntity<String> deleteItem(
            @PathVariable("itemId") Long itemId, // [수정] ("itemId") 추가
            Principal principal
    ) {
        itemService.deleteItem(principal.getName(), itemId);
        return ResponseEntity.ok("성공적으로 삭제되었습니다.");
    }

    @PostMapping("/items/voice")
    public ResponseEntity<Void> addItemByVoice(
            @RequestBody byte[] audioBytes) throws IOException { // 2. byte[]로 직접 받음

        sttService.processAudio(audioBytes); // 3. 바이트 배열을 서비스로 바로 전달

        return ResponseEntity.ok().build();
    }
}
