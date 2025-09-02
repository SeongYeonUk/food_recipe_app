package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.domain.Item;
import cau.team_refrigerator.refrigerator.domain.Refrigerator;
import cau.team_refrigerator.refrigerator.domain.User;
import cau.team_refrigerator.refrigerator.domain.dto.ItemCreateRequestDto;
import cau.team_refrigerator.refrigerator.domain.dto.ItemResponseDto;
import cau.team_refrigerator.refrigerator.domain.dto.ItemUpdateRequestDto;
import cau.team_refrigerator.refrigerator.repository.ItemRepository;
import cau.team_refrigerator.refrigerator.repository.RefrigeratorRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ItemService {

    private final ItemRepository itemRepository;
    private final RefrigeratorRepository refrigeratorRepository;
    private final UserService userService;

    //추가
    @Transactional
    public Long createItem(String userId, Long refrigeratorId, ItemCreateRequestDto requestDto) {
        User currentUser = userService.getUserById(userId);

        Refrigerator refrigerator = refrigeratorRepository.findByIdAndUser(refrigeratorId, currentUser)
                .orElseThrow(() -> new IllegalArgumentException("해당 냉장고가 없거나 접근 권한이 없습니다. id=" + refrigeratorId));

        Item item = Item.builder()
                .name(requestDto.getName())
                .registrationDate(requestDto.getRegistrationDate())
                .expiryDate(requestDto.getExpiryDate())
                .quantity(requestDto.getQuantity())
                .category(requestDto.getCategory())
                .refrigerator(refrigerator)
                .build();

        Item savedItem = itemRepository.save(item);
        return savedItem.getId();
    }

    // 조회
    public List<ItemResponseDto> findItemsByRefrigerator(String userId, Long refrigeratorId) {
        User currentUser = userService.getUserById(userId);

        refrigeratorRepository.findByIdAndUser(refrigeratorId, currentUser)
                .orElseThrow(() -> new IllegalArgumentException("해당 냉장고가 없거나 접근 권한이 없습니다. id=" + refrigeratorId));

        return itemRepository.findAllByRefrigeratorId(refrigeratorId).stream()
                .map(ItemResponseDto::new)
                .collect(Collectors.toList());
    }

    // 수정
    @Transactional
    public void updateItem(String userId, Long itemId, ItemUpdateRequestDto requestDto)
    {
        User currentUser = userService.getUserById(userId);

        Item item = itemRepository.findById(itemId)
                .orElseThrow(() -> new IllegalArgumentException("해당 아이템이 없습니다. id=" + itemId));

        // 기존 소유권 확인
        if (!item.getRefrigerator().getUser().equals(currentUser)) {
            throw new SecurityException("수정 권한이 없습니다.");
        }

        // 새로운 냉장고를 찾고, 소유권을 확인하는 로직 추가
        Refrigerator newRefrigerator = refrigeratorRepository
                .findByIdAndUser(requestDto.getRefrigeratorId(), currentUser)
                .orElseThrow(() -> new IllegalArgumentException("해당 냉장고가 없거나 접근 권한이 없습니다."));

        // Item 엔티티의 update 메소드 호출 (Refrigerator 객체도 함께 전달)
        item.update(
                requestDto.getName(),
                requestDto.getExpiryDate(),
                requestDto.getQuantity(),
                requestDto.getCategory(),
                newRefrigerator // <-- 새로운 냉장고 객체를 전달
        );
    }

    //삭제
    @Transactional
    public void deleteItem(String userId, Long itemId) {
        User currentUser = userService.getUserById(userId);

        Item item = itemRepository.findById(itemId)
                .orElseThrow(() -> new IllegalArgumentException("해당 아이템이 없습니다. id=" + itemId));

        if (!item.getRefrigerator().getUser().equals(currentUser)) {
            throw new SecurityException("삭제 권한이 없습니다.");
        }

        itemRepository.delete(item);
    }
}