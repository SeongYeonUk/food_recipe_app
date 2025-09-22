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

        Item newItem = new Item(
                ingredientName,
                LocalDate.now(),
                expiryDate,
                quantity,
                category,
                userRefrigerator
        );

        Item savedItem = itemRepository.save(newItem);

        IngredientLog log = new IngredientLog(savedItem, user);
        logRepository.save(log);

        IngredientStatics stat = ingredientStaticsRepository.findById(savedItem.getId())
                .orElseGet(() -> new IngredientStatics(savedItem));

        stat.incrementCount();
        ingredientStaticsRepository.save(stat);
    }
}