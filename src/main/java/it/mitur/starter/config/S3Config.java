package it.mitur.starter.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;

/**
 * Crea il bean S3Client usato da S3Service e (indirettamente) da AuditHelper.
 *
 * Pronto all'uso — nessun TODO: RENAME necessario.
 *
 * Se il tuo package deve scrivere su bucket S3 diversi (es. uno per audit,
 * uno per asset), aggiungi qui un secondo @Bean con un nome diverso
 * (es. @Bean("s3AssetClient")) e iniettalo con @Qualifier nel service.
 *
 * Le credenziali vengono da env vars (mai hardcoded):
 *   aws.region, aws.access-key, aws.secret-key → vedere application.properties
 */
@Configuration
public class S3Config {

    @Value("${aws.region}")
    private String region;

    @Value("${aws.access-key}")
    private String accessKey;

    @Value("${aws.secret-key}")
    private String secretKey;

    @Bean
    public S3Client s3Client() {
        return S3Client.builder()
                .region(Region.of(region))
                .credentialsProvider(
                        StaticCredentialsProvider.create(
                                AwsBasicCredentials.create(accessKey, secretKey)
                        )
                )
                .build();
    }
}
