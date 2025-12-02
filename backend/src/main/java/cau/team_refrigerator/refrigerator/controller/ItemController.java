package cau.team_refrigerator.refrigerator.controller;

import cau.team_refrigerator.refrigerator.domain.dto.GptIngredientDto;
import cau.team_refrigerator.refrigerator.domain.dto.ItemCreateRequestDto;
import cau.team_refrigerator.refrigerator.domain.dto.ItemResponseDto;
import cau.team_refrigerator.refrigerator.domain.dto.ItemUpdateRequestDto;
import cau.team_refrigerator.refrigerator.service.ItemService;
import cau.team_refrigerator.refrigerator.service.SttService;
import java.io.IOException;
import java.security.Principal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class ItemController {

    private final ItemService itemService;
    private final SttService sttService;

    public ItemController(ItemService itemService, SttService sttService) {
        this.itemService = itemService;
        this.sttService = sttService;
    }

    @PostMapping("/refrigerators/{refrigeratorId}/items")
    public ResponseEntity<Map<String, Object>> createItem(
            @PathVariable("refrigeratorId") Long refrigeratorId,
            @RequestBody ItemCreateRequestDto requestDto,
            Principal principal
    ) {
        Long newItemId = itemService.createItem(principal.getName(), refrigeratorId, requestDto);
        Map<String, Object> response = new HashMap<>();
        response.put("itemId", newItemId);
        response.put("message", "성공적으로 추가되었습니다.");
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/refrigerators/{refrigeratorId}/items")
    public ResponseEntity<List<ItemResponseDto>> getItemsInRefrigerator(
            @PathVariable("refrigeratorId") Long refrigeratorId,
            Principal principal
    ) {
        List<ItemResponseDto> items = itemService.findItemsByRefrigerator(principal.getName(), refrigeratorId);
        return ResponseEntity.ok(items);
    }

    @PutMapping("/items/{itemId}")
    public ResponseEntity<String> updateItem(
            @PathVariable("itemId") Long itemId,
            @RequestBody ItemUpdateRequestDto requestDto,
            Principal principal
    ) {
        itemService.updateItem(principal.getName(), itemId, requestDto);
        return ResponseEntity.ok("성공적으로 수정되었습니다.");
    }

    @DeleteMapping("/items/{itemId}")
    public ResponseEntity<String> deleteItem(
            @PathVariable("itemId") Long itemId,
            Principal principal
    ) {
        itemService.deleteItem(principal.getName(), itemId);
        return ResponseEntity.ok("성공적으로 삭제되었습니다.");
    }

    /**
     * 음성으로 받은 오디오를 STT+GPT로 분석하고, 저장 전 검토를 위해 재료 리스트를 반환합니다.
     */
    @PostMapping("/items/voice")
    public ResponseEntity<List<GptIngredientDto>> parseItemsByVoice(
            @RequestBody byte[] audioBytes) throws IOException {
        List<GptIngredientDto> ingredients = sttService.processAudio(audioBytes);
        return ResponseEntity.ok(ingredients);
    }

    /**
     * 사용자가 선택한 재료 리스트를 최종 저장합니다.
     */
    @PostMapping("/items/voice/confirm")
    public ResponseEntity<Map<String, Object>> saveItemsByVoice(
            @RequestBody List<GptIngredientDto> selectedItems) {
        int savedCount = sttService.saveSelectedIngredients(selectedItems);

        Map<String, Object> response = new HashMap<>();
        response.put("savedCount", savedCount);
        response.put("message", "선택한 재료가 저장되었습니다.");

        return ResponseEntity.ok(response);
    }
}
