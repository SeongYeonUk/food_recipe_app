package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.domain.*;
import cau.team_refrigerator.refrigerator.repository.IngredientLogRepository;
import cau.team_refrigerator.refrigerator.repository.IngredientStaticsRepository;
import cau.team_refrigerator.refrigerator.repository.ItemRepository;
import cau.team_refrigerator.refrigerator.repository.RefrigeratorRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;

@Service
@RequiredArgsConstructor
public class RefrigeratorService {

    private final ItemRepository itemRepository;
    private final IngredientLogRepository logRepository;
    private final RefrigeratorRepository refrigeratorRepository;
    private final IngredientStaticsRepository ingredientStaticsRepository;

    @Transactional
    public void addIngredient(String ingredientName, LocalDate expiryDate, int quantity, ItemCategory category, User user) {

        // 사용자의 냉장고 조회
        Refrigerator userRefrigerator = refrigeratorRepository.findByUser(user)
                .orElseThrow(() -> new IllegalArgumentException("해당 유저의 냉장고를 찾을 수 없습니다."));

        // --- [수정 1] Item 생성 시 Builder 사용 ---
        Item newItem = Item.builder()
                .name(ingredientName)
                .registrationDate(LocalDate.now())
                .expiryDate(expiryDate)
                .quantity(quantity)
                .category(category)
                .refrigerator(userRefrigerator)
                .build();
        // --- ---

        Item savedItem = itemRepository.save(newItem);

        // --- [수정 2] IngredientLog 생성 시 Builder 사용 (에러 발생 지점) ---
        IngredientLog log = IngredientLog.builder()
                .item(savedItem)
                .user(user)
                .build();
        // --- ---

        logRepository.save(log);

        IngredientStatics stat = ingredientStaticsRepository.findById(savedItem.getId())
                .orElseGet(() -> new IngredientStatics(savedItem)); // 참고: IngredientStatics도 Builder 패턴을 쓰는 것이 좋습니다.

        stat.incrementCount();
        ingredientStaticsRepository.save(stat);
    }
}