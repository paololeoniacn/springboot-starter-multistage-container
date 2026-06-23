package it.mitur.starter.service.utils;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import it.mitur.starter.dto.common.S3Request;
import it.mitur.starter.entity.AppInPut;
import lombok.RequiredArgsConstructor;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * Orchestratore del ciclo audit: S3 + PostgreSQL per ogni richiesta/risposta.
 *
 * TODO: RENAME — dopo aver rinominato AppInPut:
 *   - Aggiorna il tipo 'AppInPut' nelle firme dei metodi e nelle import
 *   - Aggiorna application.properties: mitur.audit.s3-path-prefix=internal/tuodominio
 *   - Il resto della logica rimane invariato
 *
 * FLUSSO STANDARD (da usare nei tuoi @Service):
 * <pre>
 *   // 1. Inizio richiesta → S3 + DB init
 *   AppInPut record = auditHelper.logRequest("myService", identifier, requestObject);
 *
 *   try {
 *       // 2. Chiama API / esegui logica
 *       String responseJson = callExternalApi(...);
 *
 *       // 3. Successo → S3 response + DB update "C"
 *       auditHelper.logUpdate(record, "myService", identifier, "C", "OK", null, responseJson);
 *
 *   } catch (Exception e) {
 *       // 4. Errore → DB update "E" (senza S3)
 *       auditHelper.logError(record, "myService", "E", "Errore chiamata API", e.getMessage());
 *   }
 * </pre>
 *
 * SICUREZZA:
 *   Il JSON NON viene mai loggato direttamente (può contenere PII).
 *   Nei log compare SOLO il path S3, mai il contenuto.
 *
 * Property: mitur.audit.s3-path-prefix — es. "internal/starter"
 *   Struttura path S3: {prefix}/{serviceName}/{tipo}/{identifier}/{timestamp}
 *   Esempio: internal/starter/myService/request/ABC123/20240101T120000000
 */
@Service
@RequiredArgsConstructor
public class AuditHelper {

    private static final Logger logger = LogManager.getLogger(AuditHelper.class);

    private final S3Service s3Service;
    private final PostgresService postgresService;
    private final ObjectMapper objectMapper;

    /** TODO: RENAME in application.properties → mitur.audit.s3-path-prefix=internal/tuodominio */
    @Value("${mitur.audit.s3-path-prefix}")
    private String s3PathPrefix;

    // ══════════════════════════════════════════════════════════════════════
    // API pubblica
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Log inizio richiesta: carica il JSON su S3 e crea la riga iniziale su DB.
     *
     * @param serviceName nome del servizio/flusso (= procName = idFlow)
     * @param identifier  identificatore univoco della richiesta
     * @param requestObject oggetto da serializzare (o String JSON già pronta)
     * @return AppInPut appena creato — passarlo a logUpdate/logError
     * @throws JsonProcessingException se la serializzazione fallisce
     *
     * TODO: RENAME — aggiorna 'AppInPut' con il tuo tipo rinominato
     */
    public AppInPut logRequest(String serviceName, String identifier, Object requestObject)
            throws JsonProcessingException {
        String json = serialize(requestObject);
        String pathJsonIn = uploadToS3(serviceName, "request", identifier, json);

        AppInPut record = postgresService.saveInitialAppInPut(identifier, serviceName, pathJsonIn);
        postgresService.logActivity(record.getId(), serviceName, "N", "Init", null, pathJsonIn);
        return record;
    }

    /**
     * Log risposta/aggiornamento: carica il JSON su S3 (opzionale) e aggiorna il DB.
     *
     * @param record       AppInPut restituito da logRequest
     * @param serviceName  nome del servizio/flusso
     * @param identifier   identificatore univoco
     * @param status       "C" = completato, "E" = errore
     * @param description  descrizione sintetica dell'esito
     * @param message      messaggio diagnostico libero (opzionale)
     * @param jsonResponse JSON da caricare su S3 (null se non c'è risposta)
     * @throws JsonProcessingException se la serializzazione fallisce
     *
     * TODO: RENAME — aggiorna 'AppInPut' con il tuo tipo rinominato
     */
    public void logUpdate(AppInPut record, String serviceName, String identifier,
            String status, String description, String message,
            String jsonResponse) throws JsonProcessingException {

        String pathJsonOut = null;
        if (jsonResponse != null) {
            pathJsonOut = uploadToS3(serviceName, "response", identifier, jsonResponse);
            record.setPathJsonOut(pathJsonOut);
        }

        record.setStatus(status);
        record.setIdentifier(identifier);
        postgresService.saveAppInPut(record);
        postgresService.logActivity(record.getId(), serviceName, status, description, message, pathJsonOut);
    }

    /**
     * Log errore senza caricamento S3 (niente risposta da persistere).
     *
     * @param record      AppInPut restituito da logRequest
     * @param serviceName nome del servizio/flusso
     * @param status      "E" = errore
     * @param description descrizione sintetica dell'errore
     * @param message     messaggio diagnostico (es. exception.getMessage())
     *
     * TODO: RENAME — aggiorna 'AppInPut' con il tuo tipo rinominato
     */
    public void logError(AppInPut record, String serviceName,
            String status, String description, String message) {
        record.setStatus(status);
        postgresService.saveAppInPut(record);
        postgresService.logActivity(record.getId(), serviceName, status, description, message, null);
    }

    // ══════════════════════════════════════════════════════════════════════
    // Metodi interni
    // ══════════════════════════════════════════════════════════════════════

    private String uploadToS3(String serviceName, String tipo, String identifier, String json) {
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd'T'HHmmssSSS"));
        String path = String.format("%s/%s/%s/%s/%s", s3PathPrefix, serviceName, tipo, identifier, timestamp);
        // Logga SOLO il path S3, mai il JSON (può contenere PII)
        logger.info("S3 upload method={} kind={} path={}", serviceName, tipo, path);
        s3Service.process(new S3Request(path, json));
        return path;
    }

    private String serialize(Object obj) throws JsonProcessingException {
        if (obj instanceof String) {
            return (String) obj;
        }
        ObjectMapper mapper = objectMapper.copy();
        mapper.setSerializationInclusion(JsonInclude.Include.NON_NULL);
        return mapper.writeValueAsString(obj);
    }
}
