package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.client.GptApiClient; // 👈 추가
import cau.team_refrigerator.refrigerator.domain.dto.ItemResponseDto; // 👈 추가
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile; // 추가
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.PutObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PresignedPutObjectRequest;

import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
public class ImageUploadService {

    private final S3Presigner s3Presigner;
    private final GptApiClient gptApiClient; // 👈 1. GPT 클라이언트 주입
    // private final OcrClient ocrClient; // OCR 클라이언트가 있다면 주입 필요

    @Value("${aws.s3.bucket}")
    private String bucket;

    // 생성자 주입
    public ImageUploadService(S3Presigner s3Presigner, GptApiClient gptApiClient) {
        this.s3Presigner = s3Presigner;
        this.gptApiClient = gptApiClient;
    }

    // Presigned URL 생성 로직 (기존 유지)
    public String getPresignedUrl(String fileName) {
        String uniqueFileName = createUniqueFileName(fileName);
        PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                .bucket(bucket)
                .key("images/" + uniqueFileName)
                .build();
        PutObjectPresignRequest presignRequest = PutObjectPresignRequest.builder()
                .signatureDuration(Duration.ofMinutes(10))
                .putObjectRequest(putObjectRequest)
                .build();
        PresignedPutObjectRequest presignedRequest = s3Presigner.presignPutObject(presignRequest);
        return presignedRequest.url().toString();
    }

    private String createUniqueFileName(String fileName) {
        return UUID.randomUUID().toString() + "-" + fileName;
    }

    // 👇👇👇 [신규 추가] OCR 결과에 GPT 날짜 추천 붙이기 👇👇👇
    // (Controller에서 이미지를 업로드하고 OCR 결과를 받을 때 사용)
    public List<ItemResponseDto> processImageForIngredients(MultipartFile file) {

        // 1. OCR 수행 (OCR 구현체에 따라 코드가 다름, 예시)
        // List<String> detectedNames = ocrClient.extractText(file); 
        // 여기서는 테스트를 위해 가짜 데이터를 넣습니다. 실제 OCR 연동시 교체하세요.
        List<String> detectedNames = List.of("콩나물", "두부");

        List<ItemResponseDto> resultList = new ArrayList<>();

        // 2. 각 재료마다 유통기한 추천받기
        for (String name : detectedNames) {
            String recommendedDate = gptApiClient.recommendExpirationDate(name);

            resultList.add(ItemResponseDto.builder()
                    .name(name)
                    .expiryDate(recommendedDate) // 👈 GPT가 추천한 날짜
                    .quantity(1)
                    .build());
        }

        return resultList;
    }
}