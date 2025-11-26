package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.client.GptApiClient; // 👈 추가
import cau.team_refrigerator.refrigerator.domain.dto.ItemResponseDto; // 👈 결과 반환용 DTO (없다면 생성 필요)
import cau.team_refrigerator.refrigerator.domain.dto.OffDto;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;

import java.util.Collections;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class BarcodeService {

    private final GptApiClient gptApiClient; // 👈 1. GPT 클라이언트 주입

    private final WebClient webClient = WebClient.builder()
            .baseUrl("https://world.openfoodfacts.org/api/v2")
            .defaultHeader(HttpHeaders.USER_AGENT, "food-recipe-app/1.0")
            .build();

    /** * [신규] 바코드 정보 조회 + GPT 유통기한 추천 통합 메서드
     * (Controller에서 이 메서드를 호출하세요)
     */
    public ItemResponseDto getProductInfoWithDate(String rawCode) {
        // 1. 기존 로직으로 상품 정보 조회 (이름, 이미지 등)
        OffDto offDto = lookup(rawCode);

        if (offDto == null) {
            throw new IllegalArgumentException("바코드 정보를 찾을 수 없습니다.");
        }

        String productName = offDto.getName(); // OffDto에 Getter가 있다고 가정

        // 2. GPT에게 유통기한 물어보기 (핵심!)
        String recommendedDate = gptApiClient.recommendExpirationDate(productName);

        // 3. 결과 합쳐서 반환
        // (ItemResponseDto는 프론트엔드 '재료 추가 화면'에 뿌려줄 DTO입니다)
        return ItemResponseDto.builder()
                .name(productName)
                .imageUrl(offDto.getImageUrl())
                .expiryDate(recommendedDate) // 👈 GPT가 준 날짜
                .build();
    }

    /** 바코드 문자열에서 숫자만 추출하여 OFF 조회 (기존 로직 유지) */
    public OffDto lookup(String rawCode) {
        String code = rawCode == null ? "" : rawCode.replaceAll("[^0-9]", "");
        if (code.length() < 8) return null;

        String fields = String.join(",",
                "code","product_name","product_name_ko",
                "generic_name","generic_name_ko",
                "brands","quantity","image_front_url",
                "product_name_en","generic_name_en"
        );

        @SuppressWarnings("unchecked")
        Map<String, Object> body;

        // 👇👇👇 [수정] try-catch로 감싸서 404 에러를 null로 처리합니다 👇👇👇
        try {
            body = webClient.get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/product/{code}")
                            .queryParam("fields", fields)
                            .queryParam("lc", "ko")
                            .build(code))
                    .retrieve()
                    .bodyToMono(Map.class)
                    .block();
        } catch (WebClientResponseException.NotFound e) {
            // 404(Not Found)가 오면 에러 내지 말고 null 반환 (상품 없음 처리)
            System.out.println("OpenFoodFacts: 상품을 찾을 수 없음 (404) - code: " + code);
            return null;
        } catch (Exception e) {
            // 그 외 에러는 로그 찍고 null
            System.err.println("OpenFoodFacts 호출 중 에러: " + e.getMessage());
            return null;
        }

        if (body == null || !(body.get("status") instanceof Number) ||
                ((Number) body.get("status")).intValue() != 1) {
            return null;
        }

        @SuppressWarnings("unchecked")
        Map<String, Object> p = (Map<String, Object>) body.getOrDefault("product", Collections.emptyMap());

        String pnKo  = (String) p.get("product_name_ko");
        String pn    = (String) p.get("product_name");
        String gnKo  = (String) p.get("generic_name_ko");
        String gn    = (String) p.get("generic_name");
        String pnEn  = (String) p.get("product_name_en");
        String gnEn  = (String) p.get("generic_name_en");
        String brands = (String) p.get("brands");
        String qty   = (String) p.get("quantity");
        String img   = (String) p.get("image_front_url");

        String name = firstNonBlank(pnKo, pn, gnKo, gn, pnEn, gnEn);

        if (!isNonBlank(name) || (isNonBlank(brands) && name.trim().equalsIgnoreCase(brands.trim()))) {
            if (isNonBlank(pnEn) && (brands == null || !pnEn.trim().equalsIgnoreCase(brands.trim()))) {
                name = pnEn.trim();
            } else if (isNonBlank(gnKo)) {
                name = concatBrand(brands, gnKo);
            } else if (isNonBlank(gn)) {
                name = concatBrand(brands, gn);
            } else if (isNonBlank(gnEn)) {
                name = concatBrand(brands, gnEn);
            } else if (isNonBlank(brands)) {
                name = brands.trim();
            } else {
                name = "";
            }
        }

        return new OffDto(
                String.valueOf(body.getOrDefault("code", code)),
                name,
                firstBrand(brands),
                qty,
                img
        );
    }

    private static boolean isNonBlank(String s) { return s != null && !s.isBlank(); }
    private static String concatBrand(String brand, String title) {
        if (!isNonBlank(title)) return brand == null ? "" : brand.trim();
        if (!isNonBlank(brand)) return title.trim();
        String t = title.trim();
        String b = brand.trim();
        if (t.toLowerCase().startsWith(b.toLowerCase())) return t;
        return b + " " + t;
    }
    private static String firstBrand(String brands) {
        if (!isNonBlank(brands)) return null;
        return brands.split(",")[0].trim();
    }
    private static String firstNonBlank(String... xs) {
        if (xs == null) return null;
        for (String s : xs) {
            if (s != null && !s.isBlank()) return s.trim();
        }
        return null;
    }
}