package cau.team_refrigerator.refrigerator.domain.dto;

import cau.team_refrigerator.refrigerator.domain.ItemCategory;
import lombok.Data; // Getter + Setter + RequiredArgsConstructor 등 포함
import lombok.NoArgsConstructor; // JSON 파싱을 위해 필수

import java.time.LocalDate;

@Data // @Getter 대신 @Data 사용 추천 (Setter 포함)
@NoArgsConstructor
public class ItemCreateRequestDto {
    private String name;
    private int quantity;

    // Spring이 JSON의 "2025-11-27" 문자열을 자동으로 LocalDate로 변환해줍니다.
    private LocalDate expiryDate;

    // 등록일은 서버에서 생성 시점(LocalDate.now())에 넣는 것이 일반적이므로, 요청에는 없어도 됩니다.
    // private LocalDate registrationDate;

    // Spring이 JSON의 "VEGETABLE" 문자열을 자동으로 Enum으로 변환해줍니다.
    private ItemCategory category;

    private int iconIndex;

    // 👇 [필수 추가] 이 필드가 없어서 컨트롤러에서 에러가 났습니다!
    private String refrigeratorType; // "FRIDGE" or "FREEZER"
}