package it.mitur.starter;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

// ═══════════════════════════════════════════════════════════════════════════════
// TODO: RENAME — rinomina questa classe (e il file) con il nome del tuo package
//   es. MyDomainApplication
//
// Se il tuo package usa funzionalità aggiuntive, aggiungi le annotazioni:
//   @EnableAsync          — per l'esecuzione asincrona (@Async)
//   @EnableScheduling     — per i task schedulati (@Scheduled)
//   @EnableRetry          — per il retry automatico (@Retryable) + dep spring-retry
// ═══════════════════════════════════════════════════════════════════════════════
@SpringBootApplication
public class StarterApplication {

    public static void main(String[] args) {
        SpringApplication.run(StarterApplication.class, args);
    }
}
