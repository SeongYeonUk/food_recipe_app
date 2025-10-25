package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.domain.dto.OffDto;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.Collections;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class BarcodeService {

    private final WebClient webClient = WebClient.builder()
            .baseUrl("https://world.openfoodfacts.org/api/v2")
            // 실제 연락 가능한 메일로 변경 권장
            .defaultHeader(HttpHeaders.USER_AGENT, "food-recipe-app/1.0 (contact: you@example.com)")
            .build();

    /** 바코드 문자열에서 숫자만 추출하여 OFF 조회 */
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
        Map<String, Object> body = webClient.get()
                .uri(uriBuilder -> uriBuilder
                        .path("/product/{code}")
                        .queryParam("fields", fields)
                        .queryParam("lc", "ko") // 한국어 우선
                        .build(code))
                .retrieve()
                .bodyToMono(Map.class)
                .block();

        if (body == null || !(body.get("status") instanceof Number) ||
                ((Number) body.get("status")).intValue() != 1) {
            return null;
        }

        @SuppressWarnings("unchecked")
        Map<String, Object> p = (Map<String, Object>) body.getOrDefault("product", Collections.emptyMap());

        // ----- 원시값 추출 -----
        String pnKo  = (String) p.get("product_name_ko");
        String pn    = (String) p.get("product_name");
        String gnKo  = (String) p.get("generic_name_ko");
        String gn    = (String) p.get("generic_name");
        String pnEn  = (String) p.get("product_name_en");   // 8801056094591 케이스에 실제 텍스트 있음
        String gnEn  = (String) p.get("generic_name_en");
        String brands = (String) p.get("brands");
        String qty   = (String) p.get("quantity");
        String img   = (String) p.get("image_front_url");

        // ----- 1) 기본 우선순위로 이름 선택 (ko → 기본 → en) -----
        String name = firstNonBlank(pnKo, pn, gnKo, gn, pnEn, gnEn);

        // ----- 2) 이름이 비었거나 브랜드와 동일하면 보정 -----
        if (!isNonBlank(name) || (isNonBlank(brands) && name.trim().equalsIgnoreCase(brands.trim()))) {

            // product_name_en에 “브랜드 + 제품명”이 들어있는 케이스를 살림
            if (isNonBlank(pnEn) && (brands == null || !pnEn.trim().equalsIgnoreCase(brands.trim()))) {
                name = pnEn.trim();
            }
            // generic 계열만 있는 경우 "브랜드 + generic"으로 합치기
            else if (isNonBlank(gnKo)) {
                name = concatBrand(brands, gnKo);
            } else if (isNonBlank(gn)) {
                name = concatBrand(brands, gn);
            } else if (isNonBlank(gnEn)) {
                name = concatBrand(brands, gnEn);
            }
            // 최후의 보루: 브랜드
            else if (isNonBlank(brands)) {
                name = brands.trim();
            } else {
                name = "";
            }
        }

        // (선택) 디버그
        System.out.println("[OFF] code=" + code +
                " | brand=" + brands +
                " | pnEn=" + pnEn +
                " | name(final)=" + name);

        return new OffDto(
                String.valueOf(body.getOrDefault("code", code)),
                name,
                firstBrand(brands),
                qty,
                img
        );
    }

    private static boolean isNonBlank(String s) {
        return s != null && !s.isBlank();
    }

    private static String concatBrand(String brand, String title) {
        if (!isNonBlank(title)) return brand == null ? "" : brand.trim();
        if (!isNonBlank(brand)) return title.trim();
        String t = title.trim();
        String b = brand.trim();
        // title이 이미 브랜드로 시작하면 중복 방지
        if (t.toLowerCase().startsWith(b.toLowerCase())) return t;
        return b + " " + t;
    }

    /** brands가 "A,B,C" 로 내려오면 첫 번째 것만 */
    private static String firstBrand(String brands) {
        if (!isNonBlank(brands)) return null;
        return brands.split(",")[0].trim();
    }

    /** 가변 인자 중 처음으로 비어있지 않은 문자열 반환 */
    private static String firstNonBlank(String... xs) {
        if (xs == null) return null;
        for (String s : xs) {
            if (s != null && !s.isBlank()) return s.trim();
        }
        return null;
    }
}
