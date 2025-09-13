// lib/services/barcode_lookup_service.dart
import 'package:openfoodfacts/openfoodfacts.dart';

class BarcodeLookupService {
  /// EAN-13 (GTIN-13) 체크디지트 검증
  static bool isValidEAN13(String code) {
    if (code.length != 13 || int.tryParse(code) == null) return false;
    final digits = code.split('').map(int.parse).toList();
    final check = digits.last;
    int sumOdd = 0;   // index 0,2,4,6,8,10
    int sumEven = 0;  // index 1,3,5,7,9,11
    for (int i = 0; i < 12; i++) {
      if (i % 2 == 0) sumOdd += digits[i];
      else sumEven += digits[i];
    }
    final calc = (10 - ((sumOdd + sumEven * 3) % 10)) % 10;
    return calc == check;
  }

  /// KO 우선 → KO 결과가 '브랜드만'이거나 공란이면 EN으로 재조회해서 name 강제 확보
  static Future<String?> findProductName(String barcode) async {
    // 전역 설정
    OpenFoodAPIConfiguration.userAgent = UserAgent(
      name: 'food_recipe_app',
      url: 'https://example.com',
    );
    OpenFoodAPIConfiguration.globalLanguages = const [
      OpenFoodFactsLanguage.KOREAN,
      OpenFoodFactsLanguage.ENGLISH,
    ];
    OpenFoodAPIConfiguration.globalCountry = OpenFoodFactsCountry.SOUTH_KOREA;

    // 1) KO 1차 조회
    final pKo = await _fetch(barcode, OpenFoodFactsLanguage.KOREAN);
    final brandKo = (pKo?.brands ?? '').trim();
    String? koBest = _pickFromAll(pKo);

    // KO가 비었거나, 결과가 브랜드와 동일하면 → EN 재조회
    if (!_nonBlank(koBest) ||
        (_nonBlank(brandKo) && koBest!.toLowerCase() == brandKo.toLowerCase())) {
      // 2) EN 재조회: 여기서는 'productName' 자체를 최우선으로 사용
      final pEn = await _fetch(barcode, OpenFoodFactsLanguage.ENGLISH);

      // 가장 강력한 신호: 언어=EN으로 조회했을 때의 기본 이름
      final enPrimary = pEn?.productName?.trim();

      // 그다음 번역맵 EN, generic EN, generic 기본 순
      final enFallback = _firstNonBlank([
        pEn?.productNameInLanguages?[OpenFoodFactsLanguage.ENGLISH],
        pEn?.genericNameInLanguages?[OpenFoodFactsLanguage.ENGLISH],
        pEn?.genericName,
      ]);

      final enBest = _firstNonBlank([enPrimary, enFallback]);

      if (_nonBlank(enBest) &&
          (! _nonBlank(brandKo) || enBest!.toLowerCase() != brandKo.toLowerCase())) {
        return enBest;
      }

      // EN에서도 이름이 안 잡히면 KO/EN generic + 브랜드 조합 시도
      final genericAny = _firstNonBlank([
        pKo?.genericNameInLanguages?[OpenFoodFactsLanguage.KOREAN],
        pKo?.genericName,
        pEn?.genericNameInLanguages?[OpenFoodFactsLanguage.ENGLISH],
        pEn?.genericName,
      ]);
      if (_nonBlank(genericAny)) return _concatBrand(brandKo, genericAny!);

      // 최후 폴백
      if (_nonBlank(brandKo)) return brandKo;
      return null;
    }

    // KO에서 이미 괜찮은 이름이면 그대로 반환
    return koBest;
  }

  /// ===== 내부 유틸 =====

  /// 지정 언어로 제품 조회 (번역맵 포함)
  static Future<Product?> _fetch(String barcode, OpenFoodFactsLanguage lang) async {
    final cfg = ProductQueryConfiguration(
      barcode,
      language: lang,
      fields: const [
        // v3 최신 필드
        ProductField.NAME,
        ProductField.GENERIC_NAME,
        ProductField.BRANDS,
        ProductField.LANGUAGE,
        ProductField.NAME_IN_LANGUAGES,
        ProductField.GENERIC_NAME_IN_LANGUAGES,
      ],
      version: ProductQueryVersion.v3,
    );
    final res = await OpenFoodAPIClient.getProductV3(cfg);
    if (res.status != ProductResultV3.statusSuccess) return null;
    return res.product;
  }

  /// 번역맵 + 기본필드에서 최선의 이름 선택 (KO 우선 → 기본 → EN → generic들)
  static String? _pickFromAll(Product? p) {
    if (p == null) return null;
    final Map<OpenFoodFactsLanguage, String>? nameTr = p.productNameInLanguages;
    final Map<OpenFoodFactsLanguage, String>? genTr  = p.genericNameInLanguages;
    final String brand = (p.brands ?? '').trim();

    final koName = nameTr?[OpenFoodFactsLanguage.KOREAN]?.trim();
    final baseName = p.productName?.trim();
    final enName = nameTr?[OpenFoodFactsLanguage.ENGLISH]?.trim();

    final koGen = genTr?[OpenFoodFactsLanguage.KOREAN]?.trim();
    final baseGen = p.genericName?.trim();
    final enGen = genTr?[OpenFoodFactsLanguage.ENGLISH]?.trim();

    String? name = _firstNonBlank([koName, baseName, enName, koGen, baseGen, enGen]);

    if (!_nonBlank(name) || (_nonBlank(brand) && name!.toLowerCase() == brand.toLowerCase())) {
      if (_nonBlank(enName) && (!_nonBlank(brand) || enName!.toLowerCase() != brand.toLowerCase())) {
        name = enName!.trim();
      } else if (_nonBlank(koGen)) {
        name = _concatBrand(brand, koGen!);
      } else if (_nonBlank(baseGen)) {
        name = _concatBrand(brand, baseGen!);
      } else if (_nonBlank(enGen)) {
        name = _concatBrand(brand, enGen!);
      } else if (_nonBlank(brand)) {
        name = brand;
      } else {
        name = null;
      }
    }
    return name;
  }

  static bool _nonBlank(String? s) => s != null && s.trim().isNotEmpty;

  static String? _firstNonBlank(List<String?> xs) {
    for (final s in xs) {
      if (s != null && s.trim().isNotEmpty) return s.trim();
    }
    return null;
  }

  static String _concatBrand(String brand, String title) {
    final t = title.trim();
    if (!_nonBlank(brand)) return t;
    final b = brand.trim();
    if (t.toLowerCase().startsWith(b.toLowerCase())) return t; // 중복 방지
    return '$b $t';
  }
}
