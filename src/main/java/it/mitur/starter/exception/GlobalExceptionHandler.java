package it.mitur.starter.exception;

import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingRequestHeaderException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

import it.mitur.starter.dto.common.ErrorResponse;

/**
 * Gestore centralizzato degli errori HTTP — tutti i controller passano da qui.
 *
 * Pronto all'uso — nessun TODO: RENAME necessario.
 *
 * Usa SLF4J direttamente (non LogUtil) perché gli errori qui sono già
 * "catturati" da Spring: non c'è logica applicativa da tracciare.
 *
 * OWASP A03 – Injection    : messaggi di errore generici in 400 (no dettagli interni).
 * OWASP A04 – Insecure Design: 400/401/500 coerenti, nessun leak di stack.
 */
@ControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    // ── 400 – Validazione @Valid fallita ────────────────────────────────────
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidation(MethodArgumentNotValidException ex) {
        List<String> messages = ex.getBindingResult()
                .getFieldErrors()
                .stream()
                .map(err -> err.getDefaultMessage())
                .toList();
        log.warn("Validazione fallita: {}", messages);
        return ResponseEntity.badRequest()
                .body(new ErrorResponse(400, String.join("; ", messages)));
    }

    // ── 400 – JSON non leggibile (incluse chiavi duplicate) ─────────────────
    // Messaggio GENERICO: non esponiamo il dettaglio dell'errore di parsing
    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ErrorResponse> handleUnreadable(HttpMessageNotReadableException ex) {
        log.warn("JSON non leggibile: {}", ex.getMessage());
        return ResponseEntity.badRequest()
                .body(new ErrorResponse(400, "Richiesta non valida."));
    }

    // ── 400 – Query parameter obbligatorio mancante ──────────────────────────
    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<ErrorResponse> handleMissingParam(MissingServletRequestParameterException ex) {
        log.warn("Parametro mancante: {}", ex.getParameterName());
        return ResponseEntity.badRequest()
                .body(new ErrorResponse(400, ex.getMessage()));
    }

    // ── 400 – Header obbligatorio mancante ──────────────────────────────────
    @ExceptionHandler(MissingRequestHeaderException.class)
    public ResponseEntity<ErrorResponse> handleMissingHeader(MissingRequestHeaderException ex) {
        log.warn("Header mancante: {}", ex.getHeaderName());
        return ResponseEntity.badRequest()
                .body(new ErrorResponse(400, ex.getMessage()));
    }

    // ── 401 – JWT/token non valido ───────────────────────────────────────────
    // Handler dedicato per IllegalAccessException lanciata dal filtro JWT.
    // TODO: se usi Spring Security con JWT, sostituisci con il tuo AuthenticationException.
    @ExceptionHandler(IllegalAccessException.class)
    public ResponseEntity<ErrorResponse> handleUnauthorized(IllegalAccessException ex) {
        log.warn("Accesso non autorizzato: {}", ex.getMessage());
        return ResponseEntity.status(401)
                .body(new ErrorResponse(401, "Non autorizzato."));
    }

    // ── 400/500 – Eccezione generica catch-all ───────────────────────────────
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGeneric(Exception ex) {
        String msg = ex.getMessage();
        if (msg != null && msg.contains("statusCode\":400")) {
            log.warn("Eccezione generica 400: {}", msg);
            return ResponseEntity.badRequest()
                    .body(new ErrorResponse(400, msg));
        }
        log.error("Eccezione non gestita", ex);
        return ResponseEntity.internalServerError()
                .body(new ErrorResponse(500, "Errore interno del server."));
    }
}
