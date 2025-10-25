
package cau.team_refrigerator.refrigerator.service;

// 1. import 문을 모두 v2 SDK에 맞게 변경합니다.
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.PutObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PresignedPutObjectRequest;

import java.time.Duration;
import java.util.UUID;

@Service
public class ImageUploadService {

    // 2. S3Client 대신 S3Presigner를 주입받습니다.
    // Presigned URL 생성은 S3Presigner가 담당합니다.
    private final S3Presigner s3Presigner;

    @Value("${aws.s3.bucket}")
    private String bucket;

    // 생성자 주입
    public ImageUploadService(S3Presigner s3Presigner) {
        this.s3Presigner = s3Presigner;
    }

    // 3. Presigned URL 생성 로직을 v2 방식으로 변경합니다.
    public String getPresignedUrl(String fileName) {
        String uniqueFileName = createUniqueFileName(fileName);

        PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                .bucket(bucket)
                .key("images/" + uniqueFileName) // S3에 저장될 경로 및 파일명
                .build();

        PutObjectPresignRequest presignRequest = PutObjectPresignRequest.builder()
                .signatureDuration(Duration.ofMinutes(10)) // URL 유효 시간
                .putObjectRequest(putObjectRequest)
                .build();

        PresignedPutObjectRequest presignedRequest = s3Presigner.presignPutObject(presignRequest);

        return presignedRequest.url().toString();
    }

    private String createUniqueFileName(String fileName) {
        return UUID.randomUUID().toString() + "-" + fileName;
    }
}
