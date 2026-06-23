package it.mitur.starter.service.utils;

import java.time.LocalDateTime;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.springframework.stereotype.Service;

import it.mitur.starter.entity.AppActivityLog;
import it.mitur.starter.entity.AppInPut;
import it.mitur.starter.repository.AppActivityLogRepository;
import it.mitur.starter.repository.AppInPutRepository;
import lombok.RequiredArgsConstructor;

/**
 * Service di persistenza per il ciclo audit su PostgreSQL.
 *
 * TODO: RENAME — dopo aver rinominato AppInPut e AppActivityLog:
 *   - Aggiorna i tipi nelle firme dei metodi (AppInPut → tuo tipo)
 *   - Aggiorna le import delle entità rinominate
 *   - La logica interna rimane invariata
 *
 * PATTERN:
 *   Metodo unificato logActivity() append-only invece di metodi separati per tipo.
 *   Gestisce init, update ed errore passando parametri diversi.
 *
 * FLUSSO TIPICO con AuditHelper:
 *   1. saveInitialAppInPut()  → crea riga AppInPut, status="N"
 *   2. logActivity(id, ...)   → append su AppActivityLog (init)
 *   3. [dopo chiamata API]
 *      saveAppInPut(cam)      → update status="C" o "E"
 *      logActivity(id, ...)   → append su AppActivityLog (result)
 */
@Service
@RequiredArgsConstructor
public class PostgresService {

    private static final Logger logger = LogManager.getLogger(PostgresService.class);

    // TODO: RENAME — aggiorna con i repository delle entità rinominate
    private final AppInPutRepository appInPutRepository;
    private final AppActivityLogRepository appActivityLogRepository;

    // ══════════════════════════════════════════════════════════════════════
    // APP_IN_PUT (tabella principale — una riga per richiesta)
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Crea la riga iniziale per una nuova richiesta.
     * Status "N" (Nuova). pathJsonOut rimane null fino alla risposta.
     *
     * TODO: RENAME — aggiorna 'AppInPut' con il tuo tipo rinominato
     */
    public AppInPut saveInitialAppInPut(String identifier, String idFlow, String pathJsonIn) {
        AppInPut row = new AppInPut();
        row.setIdentifier(identifier);
        row.setIdFlow(idFlow);
        row.setPathJsonIn(pathJsonIn);
        row.setPathJsonOut(null);
        row.setStatus("N");
        row.setCreatedAt(LocalDateTime.now());
        row.setUpdatedAt(LocalDateTime.now());

        logger.info("Salvato AppInPut iniziale: identifier={} idFlow={}", identifier, idFlow);
        return appInPutRepository.save(row);
    }

    /**
     * Update generico su AppInPut (es. status "C" o "E", pathJsonOut).
     * Aggiorna sempre updatedAt.
     *
     * TODO: RENAME — aggiorna 'AppInPut' con il tuo tipo rinominato
     */
    public AppInPut saveAppInPut(AppInPut row) {
        row.setUpdatedAt(LocalDateTime.now());
        return appInPutRepository.save(row);
    }

    // ══════════════════════════════════════════════════════════════════════
    // APP_ACTIVITY_LOG (append-only — una riga per passo/evento)
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Aggiunge una riga di log per un passo del processo (append-only).
     *
     * Metodo unificato (append-only): supporta init, update ed errore
     * senza dover scegliere il metodo giusto. Passare null nei campi opzionali
     * se non pertinenti al passo corrente.
     *
     * @param idRequest      FK verso AppInPut.id
     * @param procName       nome del passo (max 20 char, es. "init", "callApi", "save")
     * @param resultActivity esito: "N"=nuovo, "C"=completato, "E"=errore
     * @param resultDescr    descrizione sintetica (es. "OK", "Timeout", "Dati mancanti")
     * @param message        messaggio diagnostico libero (opzionale)
     * @param pathJson       path S3 del JSON coinvolto in questo passo (opzionale)
     *
     * TODO: RENAME — aggiorna 'AppActivityLog' con il tuo tipo rinominato
     */
    public AppActivityLog logActivity(Integer idRequest, String procName,
            String resultActivity, String resultDescr,
            String message, String pathJson) {

        AppActivityLog row = new AppActivityLog();
        row.setIdRequest(idRequest);
        row.setProcName(procName);
        row.setResultActivity(resultActivity);
        row.setResultDescr(resultDescr);
        row.setMessage(message);
        row.setPathJson(pathJson);
        row.setCreatedAt(LocalDateTime.now());
        row.setUpdatedAt(LocalDateTime.now());

        return appActivityLogRepository.save(row);
    }
}
