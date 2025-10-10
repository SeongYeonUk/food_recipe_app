package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.domain.*;
import cau.team_refrigerator.refrigerator.repository.IngredientLogRepository;
import cau.team_refrigerator.refrigerator.repository.ItemRepository;
import com.google.cloud.speech.v1.*;
import com.google.protobuf.ByteString;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@Service
@Slf4j
@RequiredArgsConstructor
public class SpeechRecognitionService {

    private final ItemRepository itemRepository;
    private final IngredientLogRepository ingredientLogRepository;

    @Transactional
    public String recognizeAndLogSpeech(byte[] audioData, User user) {
        try (SpeechClient speechClient = SpeechClient.create()) {
            ByteString audioBytes = ByteString.copyFrom(audioData);

            // --- [수정 1] Recognition -> RecognitionConfig 오타 수정 ---
            RecognitionConfig config = RecognitionConfig.newBuilder()
                    .setEncoding(RecognitionConfig.AudioEncoding.LINEAR16)
                    .setSampleRateHertz(16000)
                    .setLanguageCode("ko-KR")
                    .build();
            // --- ---

            RecognitionAudio audio = RecognitionAudio.newBuilder()
                    .setContent(audioBytes)
                    .build();

            log.info("Google Cloud에 음성 인식 요청을 보냅니다...");
            RecognizeResponse response = speechClient.recognize(config, audio);
            List<SpeechRecognitionResult> results = response.getResultsList();

            if (results.isEmpty() || results.get(0).getAlternativesList().isEmpty()) {
                log.warn("음성 인식 결과가 없습니다.");
                return "음성 인식 결과가 없습니다.";
            }

            String transcript = results.get(0).getAlternativesList().get(0).getTranscript();
            log.info("인식된 텍스트: {}", transcript);

            String itemName = parseItemName(transcript);
            int quantity = parseQuantity(transcript);

            if (itemName == null || itemName.isBlank()) {
                return "아이템 이름을 인식하지 못했습니다: " + transcript;
            }

            List<Item> foundItems = itemRepository.findByName(itemName);
            Item itemToLog;

            if (foundItems.isEmpty()) {
                log.info("새로운 아이템 '{}'을(를) DB에 추가합니다.", itemName);

                // --- [수정 2] user.getPrimaryRefrigerator() 호출 확인 ---
                Refrigerator refrigerator = user.getPrimaryRefrigerator();
                if (refrigerator == null) {
                    throw new IllegalStateException("사용자에게 할당된 메인 냉장고가 없습니다.");
                }
                // --- ---

                Item newItem = Item.builder()
                        .name(itemName)
                        .quantity(quantity)
                        .registrationDate(LocalDate.now())
                        .expiryDate(LocalDate.now().plusDays(7))
                        .category(ItemCategory.기타)  //Enum에 정의된 '기타'를 기본값으로 사용
                        // --- ---
                        .refrigerator(refrigerator)
                        .build();
                itemToLog = itemRepository.save(newItem);
            } else {
                itemToLog = foundItems.get(0);
            }

            IngredientLog newLog = IngredientLog.builder()
                    .item(itemToLog)
                    .user(user)
                    .build();
            ingredientLogRepository.save(newLog);

            log.info("사용자 ID {}: '{}'에 대한 재료 로그를 저장했습니다.", user.getId(), itemToLog.getName());
            return "로그 저장 완료: " + transcript;

        } catch (Exception e) {
            log.error("음성 인식 중 오류 발생", e);
            throw new RuntimeException("음성 인식에 실패했습니다.", e);
        }
    }

    private String parseItemName(String text) {
        if (text == null || text.isBlank()) {
            return null;
        }
        return text.split(" ")[0];
    }

    private int parseQuantity(String text) {
        if (text == null || text.isBlank()) {
            return 1;
        }
        return 1;
    }
}