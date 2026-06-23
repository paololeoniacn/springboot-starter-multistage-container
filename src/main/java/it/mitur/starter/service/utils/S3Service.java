package it.mitur.starter.service.utils;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import it.mitur.starter.dto.common.S3Request;
import lombok.RequiredArgsConstructor;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

/**
 * Service per il caricamento su Amazon S3.
 *
 * Pronto all'uso — nessun TODO: RENAME necessario.
 *
 * PATTERN DI UPLOAD (process):
 *   dato il path base "internal/starter/myService/request/ABC/20240101T120000000":
 *   1. {path}.json   — contenuto JSON della richiesta/risposta
 *   2. backup/{data}/{path}.json — copia di backup con prefisso data
 *   3. {path}.trg    — file trigger vuoto (segnala al consumer che il JSON è pronto)
 *
 * Property: aws.s3.bucket-name → nome bucket da env var AWS_BUCKET_NAME
 *
 * Il bean S3Client è definito in S3Config e iniettato via costruttore.
 */
@Service
@RequiredArgsConstructor
public class S3Service {

    private static final Logger logger = LogManager.getLogger(S3Service.class);

    private final S3Client s3Client;

    @Value("${aws.s3.bucket-name}")
    private String bucketName;

    /**
     * Carica su S3 il JSON della richiesta/risposta nel pattern a 3 file.
     *
     * @param request contiene pathS3 (base, senza estensione) e jsonString
     */
    public void process(S3Request request) {
        String basePath = request.getPathS3();
        String jsonPath   = basePath + ".json";
        String trgPath    = basePath + ".trg";
        String backupPath = String.format("backup/%s/%s.json",
                LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd")),
                basePath);

        logger.info("S3 upload: path={}", basePath);
        putObject(jsonPath, request.getJsonString());
        putObject(backupPath, request.getJsonString());
        putObject(trgPath, "");
    }

    /**
     * Upload diretto di un array di byte (es. immagine).
     *
     * @param imageBytes contenuto da caricare
     * @param finalPath  chiave S3 completa (con estensione)
     */
    public void uploadImage(byte[] imageBytes, String finalPath) {
        logger.info("S3 upload image: path={}", finalPath);
        PutObjectRequest putRequest = PutObjectRequest.builder()
                .bucket(bucketName)
                .key(finalPath)
                .build();
        s3Client.putObject(putRequest, RequestBody.fromBytes(imageBytes));
    }

    private void putObject(String key, String content) {
        PutObjectRequest putRequest = PutObjectRequest.builder()
                .bucket(bucketName)
                .key(key)
                .build();
        s3Client.putObject(putRequest, RequestBody.fromString(content));
    }
}
