package it.mitur.starter.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

/**
 * Tabella di configurazione anagrafica condivisa tra tutti i package MiTur.
 *
 * Pronto all'uso — nessun TODO: RENAME necessario.
 *
 * Struttura: ogni riga è un parametro identificato dalla tripla (cdFlow, cdType, cdKey).
 * Usata per configurazioni runtime senza deploy: soglie, flag, URL, costanti di dominio.
 *
 * Esempio di query nel repository:
 *   List<AnagParameter> params = anagRepo.findByCdFlowAndCdType("MY_FLOW", "CONFIG");
 */
@Entity
@Getter
@Setter
@Table(name = "anag_parameter")
public class AnagParameter {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    /** Descrizione leggibile del parametro. */
    private String description;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    /** Valore del parametro. */
    @Column(name = "cd_value", nullable = false)
    private String cdValue;

    /** Categoria/tipo del parametro (es. "CONFIG", "FLAG", "THRESHOLD"). */
    @Column(name = "cd_type", nullable = false)
    private String cdType;

    /** Chiave del parametro (es. "MAX_RETRY", "API_URL", "ENABLED"). */
    @Column(name = "cd_key", nullable = false)
    private String cdKey;

    /** Flusso/dominio di appartenenza (es. "MY_FLOW", "FLOW_B"). */
    @Column(name = "cd_flow")
    private String cdFlow;
}
