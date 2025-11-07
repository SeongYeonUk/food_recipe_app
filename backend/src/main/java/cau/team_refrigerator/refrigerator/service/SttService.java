// /service/SttService.java

package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.client.SttClient;
import cau.team_refrigerator.refrigerator.client.GptApiClient;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;

/*
# 1. 현재 브랜치 확인
git branch

# 2. main 브랜치로 이동
git checkout main

# 3. 최신 main으로 업데이트 (다른 사람 작업 반영용)
git pull origin main

# 4. 아까 작업한 브랜치(main으로 합칠 브랜치)를 merge
git merge [브랜치이름]

# 5. 충돌 없으면 커밋 완료됨
# 이제 원격(main)에 push
git push origin main

 */
@Service
public class SttService {

    private final SttClient sttClient;
    private final GptApiClient gptApiClient;

    // private final ItemService itemService;

    // 생성자를 통해 SttClient를 주입받음
    public SttService(SttClient sttClient, GptApiClient gptApiClient) {
        this.sttClient = sttClient;
        this.gptApiClient = gptApiClient;
    }

    public void processAudio(MultipartFile audioFile) throws IOException {

        // 1. MultipartFile을 byte[]로 변환
        byte[] audioBytes = audioFile.getBytes();

        // 2. STT API 호출
        String sttText = sttClient.callGoogleSttApi(audioBytes);
        System.out.println("STT 결과: " + sttText);

        // (만약 인식된 텍스트가 없다면 여기서 중단)
        if (sttText == null || sttText.contains("인식된 텍스트 없음")) {
            System.out.println("인식된 텍스트가 없어 GPT 호출을 중단합니다.");
            return;
        }

        // --- ⬇️ ⬇️ ⬇️ 여기가 새로 추가된 핵심 로직 ⬇️ ⬇️ ⬇️ ---

        // 3. STT 결과를 GPT API로 전송
        System.out.println("GPT API 호출 중...");
        String gptJsonResult = gptApiClient.callGptApi(sttText);

        // 4. GPT가 분석한 JSON 결과 출력
        System.out.println("GPT 분석 결과 (DB 저장용 JSON): " + gptJsonResult);

        // --- ⬆️ ⬆️ ⬆️ 추가 로직 끝 ⬆️ ⬆️ ⬆️ ---

        // (구현 예정) 5. gptJsonResult를 DTO로 파싱하고 '안전장치' 검증
        // List<ItemDto> items = validateAndParse(gptJsonResult);
        // itemService.saveItems(items);
    }
}