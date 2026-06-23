package it.mitur.starter.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

// ═══════════════════════════════════════════════════════════════════════════
// TODO: RENAME — questa entità è un template, rinomina prima di usarla:
//
//   1. Classe: 'AppInPut' → '{Prefisso}InPut'  (es. MyDomainInPut)
//   2. Tabella: 'app_in_put' → '{prefisso}_in_put'  (es. myd_in_put)
//   3. Aggiorna AppInPutRepository con il nuovo tipo
//   4. Aggiorna PostgresService e AuditHelper con il nuovo tipo
//
// Dopo il rename la classe è pronta all'uso senza altre modifiche.
// ═══════════════════════════════════════════════════════════════════════════
@Entity
@Table(name = "app_in_put")
@Getter
@Setter
public class AppInPut {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    /** Identificatore univoco della richiesta (es. CF, codice struttura, ID cliente). */
    @Column(nullable = false)
    private String identifier;

    /** Nome del flusso/servizio che ha generato questa richiesta (= procName). */
    @Column(name = "id_flow", nullable = false)
    private String idFlow;

    /** Path S3 del JSON di input (mai il JSON diretto — solo il percorso). */
    @Column(name = "path_json_in", nullable = false, columnDefinition = "TEXT")
    private String pathJsonIn;

    /** Path S3 del JSON di output (valorizzato dopo la risposta). */
    @Column(name = "path_json_out", columnDefinition = "TEXT")
    private String pathJsonOut;

    /**
     * Stato della richiesta:
     *   "N" = Nuova (init)
     *   "C" = Completata con successo
     *   "E" = Errore
     */
    @Column(nullable = false)
    private String status;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
