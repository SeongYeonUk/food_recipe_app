package cau.team_refrigerator.refrigerator.controller;

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
}
