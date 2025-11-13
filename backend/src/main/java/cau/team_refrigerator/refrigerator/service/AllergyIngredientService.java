package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.domain.AllergyIngredient;
import cau.team_refrigerator.refrigerator.domain.Ingredient;
import cau.team_refrigerator.refrigerator.domain.User;
import cau.team_refrigerator.refrigerator.domain.dto.AllergyIngredientRequestDto;
import cau.team_refrigerator.refrigerator.domain.dto.AllergyIngredientResponseDto;
import cau.team_refrigerator.refrigerator.repository.AllergyIngredientRepository;
import cau.team_refrigerator.refrigerator.repository.IngredientRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AllergyIngredientService {

    private final AllergyIngredientRepository allergyIngredientRepository;
    private final IngredientRepository ingredientRepository;

    @Transactional(readOnly = true)
    public List<AllergyIngredientResponseDto> getAll(User user) {
        return allergyIngredientRepository.findAllByUserOrderByCreatedAtAsc(user)
                .stream()
                .map(AllergyIngredientResponseDto::from)
                .collect(Collectors.toList());
    }

    @Transactional
    public AllergyIngredientResponseDto add(User user, AllergyIngredientRequestDto requestDto) {
        Ingredient ingredient = resolveIngredient(requestDto);
        if (allergyIngredientRepository.existsByUserAndIngredient(user, ingredient)) {
            throw new IllegalArgumentException("이미 등록된 알레르기 식재료입니다.");
        }
        AllergyIngredient saved = allergyIngredientRepository.save(new AllergyIngredient(user, ingredient));
        return AllergyIngredientResponseDto.from(saved);
    }

    @Transactional
    public void delete(User user, Long allergyId) {
        AllergyIngredient allergy = allergyIngredientRepository.findByIdAndUser(allergyId, user)
                .orElseThrow(() -> new IllegalArgumentException("알레르기 식재료를 찾을 수 없습니다."));
        allergyIngredientRepository.delete(allergy);
    }

    private Ingredient resolveIngredient(AllergyIngredientRequestDto requestDto) {
        if (requestDto.getIngredientId() != null) {
            return ingredientRepository.findById(requestDto.getIngredientId())
                    .orElseThrow(() -> new IllegalArgumentException("식재료를 찾을 수 없습니다. ID: " + requestDto.getIngredientId()));
        }
        String sanitized = sanitizeName(requestDto.getName());
        if (sanitized == null) {
            throw new IllegalArgumentException("추가할 식재료를 선택하거나 이름을 입력해 주세요.");
        }
        return ingredientRepository.findByNameIgnoreCase(sanitized)
                .orElseThrow(() -> new IllegalArgumentException("식재료 목록에서 '" + sanitized + "' 을(를) 찾을 수 없습니다."));
    }

    private String sanitizeName(String name) {
        if (name == null) {
            return null;
        }
        String trimmed = name.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
