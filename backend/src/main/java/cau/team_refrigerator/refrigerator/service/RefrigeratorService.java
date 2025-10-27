package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.domain.*;
import cau.team_refrigerator.refrigerator.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
public class RefrigeratorService {

    private final IngredientRepository ingredientRepository;
    private final ItemRepository itemRepository;
    private final IngredientLogRepository logRepository;
    private final RefrigeratorRepository refrigeratorRepository;
    private final IngredientStaticsRepository ingredientStaticsRepository;

    // RefrigeratorService.java 내부

    @Transactional
    public void addIngredient(String ingredientName, LocalDate expiryDate, int quantity,
                              ItemCategory category, User user, RefrigeratorType refrigeratorType) {

        // 1. 사용자의 해당 타입 냉장고 찾기 (이전 수정 코드)
        List<Refrigerator> userRefrigerators = refrigeratorRepository.findByUser(user);
        Refrigerator targetRefrigerator = userRefrigerators.stream()
                .filter(ref -> ref.getType() == refrigeratorType)
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("해당 유저의 [" + refrigeratorType + "] 타입 냉장고를 찾을 수 없습니다."));

        // 2. Item 생성
        Item newItem = Item.builder()
                .name(ingredientName) // String name 필드 사용
                .registrationDate(LocalDate.now())
                .expiryDate(expiryDate)
                .quantity(quantity)
                .category(category)
                .refrigerator(targetRefrigerator)
                .build();

        // 3. Item 저장
        Item savedItem = itemRepository.save(newItem);

        // 👇👇👇 4. Ingredient 테이블에도 이름 등록 (없으면 생성) 👇👇👇
        findOrCreateIngredient(ingredientName); // 이 줄 추가!

        // 5. 로그 및 통계 저장 (기존 코드)
        IngredientLog log = new IngredientLog(savedItem, user);
        logRepository.save(log);
        IngredientStatics stat = ingredientStaticsRepository.findById(savedItem.getId())
                .orElseGet(() -> new IngredientStatics(savedItem));
        stat.incrementCount();
        ingredientStaticsRepository.save(stat);
    }


    private Ingredient findOrCreateIngredient(String name) {
        String trimmedName = name.trim();
        return ingredientRepository.findByName(trimmedName)
                .orElseGet(() -> {
                    System.out.println("냉장고 추가 시 새로운 재료 발견 및 저장: " + trimmedName);
                    return ingredientRepository.save(Ingredient.builder().name(trimmedName).build());
                });
    }
}