package it.mitur.starter.utils;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import jakarta.annotation.PostConstruct;

/**
 * ═══════════════════════════════════════════════════════════════════
 * LOGUTIL — GUIDA RAPIDA (READ-ME)
 *
 * SCOPO
 * Centralizza il logging degli errori in modo sicuro per la produzione:
 * niente stacktrace a livello ERROR, messaggi chiari e comportamento
 * configurabile con una sola property in application.properties.
 *
 * COMPORTAMENTO
 * - Livello ERROR:
 *     • Non stampa MAI lo stacktrace (evita leak di dettagli sensibili).
 *     • Può aggiungere opzionalmente SOLO e.getMessage() (vedi override).
 *     • Tutti i messaggi ERROR hanno il prefisso ❌ per scanning visivo rapido.
 * - Livello DEBUG:
 *     • Stampa lo stacktrace completo (utile in DEV o in troubleshooting).
 *
 * CONFIGURAZIONE DI DEFAULT
 * - L'ambiente è impostato via ENV → spring.profiles.active → env
 * - Regola di default (quando l'override è assente/commentato):
 *     • env = PROD | prod | production → includeExceptionMessage = false
 *     • altrimenti → includeExceptionMessage = true
 *
 * OVERRIDE OPZIONALE (per diagnostica temporanea in PROD)
 * - Decommentare in application.properties: mitur.logging.include-exception-message=true
 * - L'override vince sempre sull'ambiente.
 * - Flusso consigliato:
 *     1. Decommentare e impostare a true
 *     2. Deploy veloce → analizzare i log ERROR (con e.getMessage())
 *     3. Ricommentare → riportare al comportamento basato su env
 *
 * ESEMPIO D'USO
 * try {
 *     // ...
 * } catch (Exception e) {
 *     LogUtil.error(log, "Errore nel processo di Create CF", e);
 * }
 * - In PROD (override commentato): "❌ Errore nel processo di Create CF"
 * - In PROD (override=true):       "❌ Errore nel processo di Create CF | exception=Connection reset"
 * - In DEBUG:                       oltre alla riga ERROR, compare lo stacktrace a DEBUG.
 * ═══════════════════════════════════════════════════════════════════
 */
@Component
public class LogUtil {

    /**
     * Flag globale: se TRUE aggiunge e.getMessage() all'ERROR.
     * Volatile per sicurezza multi-thread (anche se il write è solo al PostConstruct).
     */
    private static volatile boolean includeExceptionMessage = true;

    @Value("${env:not-defined}")
    private String envName;

    // Stringa (non boolean) perché @Value su boolean non distingue "assente" da "false"
    @Value("${mitur.logging.include-exception-message:}")
    private String includeExceptionOverride;

    @PostConstruct
    void initLogError() {
        if (includeExceptionOverride != null && !includeExceptionOverride.isBlank()) {
            includeExceptionMessage = Boolean.parseBoolean(includeExceptionOverride.trim());
        } else {
            includeExceptionMessage = !isProd(envName);
        }
        LogManager.getLogger(LogUtil.class)
                .info("LogUtil: includeExceptionMessage={} (env={})", includeExceptionMessage, envName);
    }

    private static boolean isProd(String v) {
        if (v == null) return false;
        String s = v.trim().toLowerCase();
        return "prod".equals(s) || "production".equals(s);
    }

    // ═══════════════════════════════════════════════════════════════
    // API — Log4j2 Logger (usato direttamente con LogManager.getLogger)
    // ═══════════════════════════════════════════════════════════════

    /** ERROR senza eccezione — solo messaggio generico con prefisso ❌. */
    public static void error(Logger log, String msg) {
        log.error("❌ {}", msg);
    }

    /**
     * ERROR con eccezione:
     * - a livello ERROR: MAI stacktrace; opzionalmente solo e.getMessage().
     * - a livello DEBUG: stampa lo stacktrace completo.
     */
    public static void error(Logger log, String msg, Throwable t) {
        if (t != null && includeExceptionMessage) {
            log.error("❌ {} | exception={}", msg, t.getMessage());
        } else {
            log.error("❌ {}", msg);
        }
        if (t != null && log.isDebugEnabled()) {
            log.debug("debug details", t);
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // API — SLF4J Logger (overload per Lombok @Slf4j o logback diretto)
    // ═══════════════════════════════════════════════════════════════

    /** ERROR senza eccezione — versione SLF4J. */
    public static void error(org.slf4j.Logger log, String msg) {
        log.error("❌ {}", msg);
    }

    /** ERROR con eccezione — versione SLF4J. */
    public static void error(org.slf4j.Logger log, String msg, Throwable t) {
        if (t != null && includeExceptionMessage) {
            log.error("❌ {} | exception={}", msg, t.getMessage());
        } else {
            log.error("❌ {}", msg);
        }
        if (t != null && log.isDebugEnabled()) {
            log.debug("debug details", t);
        }
    }
}
