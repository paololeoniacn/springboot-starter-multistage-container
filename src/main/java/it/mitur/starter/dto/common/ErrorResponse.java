package it.mitur.starter.dto.common;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Risposta di errore standard per tutti gli endpoint REST MiTur.
 *
 * Pronto all'uso — nessun TODO: RENAME necessario.
 *
 * Usato da GlobalExceptionHandler e dai service per rispondere con
 * un formato coerente in tutti i package MiTur.
 *
 * Preferito a RFC 7807 ProblemDetail per semplicità e coerenza interna.
 *
 * Esempio JSON:
 *   { "errorCode": 400, "message": "Richiesta non valida." }
 *   { "errorCode": 500, "message": "Errore interno del server." }
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ErrorResponse {

    /** Codice HTTP dell'errore (es. 400, 401, 500). */
    private int errorCode;

    /** Messaggio leggibile da esporre al chiamante. Evitare dettagli interni in produzione. */
    private String message;
}
