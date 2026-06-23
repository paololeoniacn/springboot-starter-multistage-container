package it.mitur.starter.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

// ═══════════════════════════════════════════════════════════════════════════
// TODO: RENAME — questa entità è un template, rinomina prima di usarla:
//
//   1. Classe: 'AppActivityLog' → '{Prefisso}ActivityLog'  (es. MyDomainActivityLog)
//   2. Tabella: 'app_activity_log' → '{prefisso}_activity_log'  (es. myd_activity_log)
//   3. Aggiorna AppActivityLogRepository con il nuovo tipo
//   4. Aggiorna PostgresService e AuditHelper con il nuovo tipo
//
// Dopo il rename la classe è pronta all'uso senza altre modifiche.
// ═══════════════════════════════════════════════════════════════════════════
@Entity
@Getter
@Setter
@Table(name = "app_activity_log")
public class AppActivityLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_log")
    private Integer idLog;

    /** FK verso AppInPut.id — identifica la richiesta padre. */
    @Column(name = "id_request")
    private Integer idRequest;

    /** Nome del passo/processo (max 20 char). Es.: "init", "callApi", "save". */
    @Column(name = "proc_name", length = 20)
    @Size(max = 20, message = "Il campo procName non può superare 20 caratteri")
    private String procName;

    /**
     * Esito dell'attività:
     *   "N" = In corso
     *   "C" = Completata
     *   "E" = Errore
     */
    @Column(name = "result_activity")
    private String resultActivity;

    /** Descrizione sintetica dell'esito (es. "OK", "Timeout API", "Dati mancanti"). */
    @Column(name = "result_descr")
    private String resultDescr;

    /** Path S3 del JSON coinvolto in questo passo (opzionale). */
    @Column(name = "path_json", columnDefinition = "TEXT")
    private String pathJson;

    /** Messaggio diagnostico libero (opzionale — es. exception.getMessage()). */
    @Column(name = "message", columnDefinition = "TEXT")
    private String message;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
