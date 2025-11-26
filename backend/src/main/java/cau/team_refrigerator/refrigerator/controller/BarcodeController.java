package cau.team_refrigerator.refrigerator.controller;

import cau.team_refrigerator.refrigerator.domain.dto.ItemResponseDto;
import cau.team_refrigerator.refrigerator.domain.dto.OffDto;
import cau.team_refrigerator.refrigerator.service.BarcodeService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/barcode")
@RequiredArgsConstructor
public class BarcodeController {

    private final BarcodeService barcodeService;

    @GetMapping("/{code}")
    public ResponseEntity<OffDto> get(@PathVariable String code) {
        OffDto dto = barcodeService.lookup(code);
        if (dto == null) return ResponseEntity.notFound().build();
        return ResponseEntity.ok(dto);
    }
    @GetMapping("/lookup") // 혹은 @PostMapping
    public ResponseEntity<ItemResponseDto> lookupBarcode(@RequestParam String barcode) {

        // ❌ (이전 코드) lookup 메서드는 유통기한을 안 줍니다.
        // OffDto result = barcodeService.lookup(barcode);

        // ✅ (수정해야 할 코드) 방금 만든 'WithDate' 메서드를 호출해야 합니다!
        ItemResponseDto result = barcodeService.getProductInfoWithDate(barcode);

        return ResponseEntity.ok(result);
    }
}
