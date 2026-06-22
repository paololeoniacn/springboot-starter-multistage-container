package it.mitur.utilityservice.handler;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import jakarta.servlet.http.HttpServletRequest;
import java.net.URI;
import java.util.List;

/**
 * Global exception handler — RFC 7807 ProblemDetail.
 *
 * OWASP A04 – Insecure Design: nessuno stack trace esposto nelle response.
 * OWASP A09 – Logging Failures: errori loggati server-side con contesto.
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    /** Errori di validazione @Valid / @Validated */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ProblemDetail handleValidation(MethodArgumentNotValidException ex,
                                          HttpServletRequest request) {
        List<String> errors = ex.getBindingResult().getFieldErrors().stream()
                .map(e -> e.getField() + ": " + e.getDefaultMessage())
                .toList();

        log.warn("Validation failed on {}: {}", request.getRequestURI(), errors);

        ProblemDetail pd = ProblemDetail.forStatusAndDetail(
                HttpStatus.BAD_REQUEST, "Validation failed");
        pd.setTitle("Bad Request");
        pd.setType(URI.create("urn:problem:validation-error"));
        pd.setProperty("errors", errors);
        return pd;
    }

    /** Catch-all: nessun dettaglio interno esposto al client */
    @ExceptionHandler(Exception.class)
    public ProblemDetail handleGeneric(Exception ex, HttpServletRequest request) {
        // OWASP A04: logga internamente, non esporre stack trace
        log.error("Unhandled exception on {}", request.getRequestURI(), ex);

        ProblemDetail pd = ProblemDetail.forStatusAndDetail(
                HttpStatus.INTERNAL_SERVER_ERROR, "An internal error occurred");
        pd.setTitle("Internal Server Error");
        pd.setType(URI.create("urn:problem:internal-error"));
        return pd;
    }
}
