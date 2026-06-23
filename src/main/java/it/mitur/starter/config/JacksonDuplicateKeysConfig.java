package it.mitur.starter.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.jackson.Jackson2ObjectMapperBuilderCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.fasterxml.jackson.core.JsonParser;

/**
 * Rifiuta i JSON con chiavi duplicate nel body della richiesta.
 *
 * Pronto all'uso — nessun TODO: RENAME necessario.
 *
 * Senza questa config il default Jackson è "last-wins" (l'ultima chiave vince):
 *   {"a":1,"a":2}  →  a=2  (silenzioso, potenzialmente pericoloso)
 * Con questa config:
 *   {"a":1,"a":2}  →  400 Bad Request  (gestito da GlobalExceptionHandler)
 *
 * Property: mitur.json.reject-duplicate-keys=true (default in application.properties)
 */
@Configuration
public class JacksonDuplicateKeysConfig {

    @Bean
    Jackson2ObjectMapperBuilderCustomizer duplicateKeysCustomizer(
            @Value("${mitur.json.reject-duplicate-keys:true}") boolean reject) {
        return builder -> {
            if (reject) {
                builder.featuresToEnable(JsonParser.Feature.STRICT_DUPLICATE_DETECTION);
            }
        };
    }
}
