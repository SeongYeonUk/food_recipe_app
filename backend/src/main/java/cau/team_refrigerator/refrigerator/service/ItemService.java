package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.domain.Item;
import cau.team_refrigerator.refrigerator.domain.Refrigerator;
import cau.team_refrigerator.refrigerator.domain.dto.ItemCreateRequestDto;
import cau.team_refrigerator.refrigerator.domain.dto.ItemResponseDto;
import cau.team_refrigerator.refrigerator.domain.dto.ItemUpdateRequestDto;
import cau.team_refrigerator.refrigerator.repository.ItemRepository;
import cau.team_refrigerator.refrigerator.repository.RefrigeratorRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true) // 클래스 전체에 읽기 전용 트랜잭션 적용
public class ItemService
{

    private final ItemRepository itemRepository;
    private final RefrigeratorRepository refrigeratorRepository;


    // 식재료 추가(Create)
    @Transactional
    public Long createItem(Long refrigeratorId, ItemCreateRequestDto requestDto)
    {

        // 요청받은 ID로 냉장고 찾기. 없으면 예외 발생
        Refrigerator refrigerator = refrigeratorRepository.findById(refrigeratorId)
                .orElseThrow(() -> new IllegalArgumentException("해당 냉장고가 없습니다. id=" + refrigeratorId));

        // Item 엔티티 생성
        // 이름, 등록일, 만료일, 양, 종류, 냉장고
        Item item = Item.builder()
                .name(requestDto.getName())
                .registrationDate(requestDto.getRegistrationDate())
                .expiryDate(requestDto.getExpiryDate())
                .quantity(requestDto.getQuantity())
                .category(requestDto.getCategory())
                .refrigerator(refrigerator)
                .build();

        // 생성된 Item 엔티티를 데이터베이스에 저장합니다.
        Item savedItem = itemRepository.save(item);

        return savedItem.getId();
    }

    public List<ItemResponseDto> findItemsByRefrigerator(Long refrigeratorId)
    {
        // 1. findAll: 모든 데이터를 리스트 형태로 반환
        List<Item> items = itemRepository.findAllByRefrigeratorId(refrigeratorId);

        // 2. 조회한 Item 엔티티 목록을 ItemResponseDto 목록으로 변환합니다.
        List<ItemResponseDto> dtoList = new ArrayList<>();

        for (Item item : items)
        {
            ItemResponseDto dto = new ItemResponseDto(item);

            dtoList.add(dto);
        }

        return dtoList;
    }

    // 식재료 수정(Update)
    @Transactional
    public void updateItem(Long itemId, ItemUpdateRequestDto requestDto)
    {
        // 1. ID로 수정할 Item을 조회합니다. 없으면 예외를 던집니다.
        Item item = itemRepository.findById(itemId)
                .orElseThrow(() -> new IllegalArgumentException("해당 아이템이 없습니다. id=" + itemId));

        // 2. Item 엔티티에 만들어둔 update 메소드를 호출하여 정보를 변경합니다.
        item.update(
                requestDto.getName(),
                requestDto.getExpiryDate(),
                requestDto.getQuantity(),
                requestDto.getCategory()
        );

        // @Transactional에 의해 메소드가 종료되면 JPA가 변경된 내용을 감지(Dirty Checking)하여
        // 자동으로 UPDATE 쿼리를 날려주므로, itemRepository.save()를 호출할 필요가 없습니다.
    }

    //식재료 삭제(Delete)
    @Transactional
    public void deleteItem(Long itemId)
    {
        // 1. ID로 삭제할 Item이 실제로 존재하는지 확인합니다.
        Item item = itemRepository.findById(itemId)
                .orElseThrow(() -> new IllegalArgumentException("해당 아이템이 없습니다. id=" + itemId));

        // 2. JpaRepository의 delete 메소드를 사용하여 DB에서 삭제합니다.
        itemRepository.delete(item);
    }



}