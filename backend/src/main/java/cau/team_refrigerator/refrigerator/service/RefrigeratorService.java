package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.domain.*;
import cau.team_refrigerator.refrigerator.repository.IngredientLogRepository;
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

    @Transactional
    public void addIngredient(String ingredientName, LocalDate expiryDate, int quantity, ItemCategory category, User user) {

        // 사용자의 냉장고 조회
        Refrigerator userRefrigerator = refrigeratorRepository.findByUser(user)
                .orElseThrow(() -> new IllegalArgumentException("해당 유저의 냉장고를 찾을 수 없습니다."));

        // Item 객체 생성
        Item newItem = new Item(
                ingredientName,
                LocalDate.now(),
                expiryDate,
                quantity,
                category,
                userRefrigerator
        );

        itemRepository.save(newItem);

        // 통계를 로그
        IngredientLog log = new IngredientLog(ingredientName, user);
        logRepository.save(log);
    }
}