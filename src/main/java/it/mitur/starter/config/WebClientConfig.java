package it.mitur.starter.config;

import java.time.Duration;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.client.reactive.ReactorClientHttpConnector;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.ExchangeFilterFunction;
import org.springframework.web.reactive.function.client.WebClient;

import lombok.RequiredArgsConstructor;
import reactor.core.publisher.Mono;
import reactor.netty.http.client.HttpClient;
import reactor.netty.resources.ConnectionProvider;

/**
 * Configurazione WebClient — connection pool PSN + bean client per ogni API esterna.
 *
 * TODO: RENAME — per ogni API esterna del tuo package:
 *   1. Aggiungi una @Value per il baseUrl (in application.properties)
 *   2. Copia il bean exampleApiClient() e rinominalo con il nome dell'API
 *   3. Rimuovi exampleApiClient() quando non è più il bean "di esempio"
 *
 * PATTERN CONSIGLIATO per nuovi client:
 *   @Value("${mitur.api.YOUR_API.base-url}")
 *   private String yourApiBaseUrl;
 *
 *   @Bean("yourApiClient")
 *   public WebClient yourApiClient() {
 *       return WebClient.builder()
 *               .clientConnector(new ReactorClientHttpConnector(buildHttpClient()))
 *               .baseUrl(yourApiBaseUrl)
 *               .defaultHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
 *               .filter(webClientUrlFilter())
 *               .build();
 *   }
 *
 * ATTENZIONE — responseTimeout(60s):
 *   Impedisce che WebClient si blocchi indefinitamente se l'API non risponde.
 *   CRUCIALE in produzione: senza di esso un'API down congela il thread di
 *   risposta fino al timeout TCP (minuti). Valore 60s: ragionevole per API REST.
 *
 * POOL — maxIdleTime(240s):
 *   Mantiene le connessioni attive per 240s (< 330s = idle PSN ~5.5min).
 *   Evita connessioni "stale" per cui il PSN ha già chiuso l'altro capo.
 */
@Component
@Configuration
@RequiredArgsConstructor
public class WebClientConfig {

    @Value("${webclient.max-idle-time-seconds}")
    private int maxIdleTimeSeconds;

    // TODO: RENAME — aggiungi qui i baseUrl delle tue API esterne
    // @Value("${mitur.api.example.base-url}")
    // private String exampleApiBaseUrl;

    private static final Logger log = LogManager.getLogger(WebClientConfig.class);

    @Bean(name = "psnConnectionProvider")
    public ConnectionProvider psnConnectionProvider() {
        return ConnectionProvider.builder("psn-pool")
                .maxIdleTime(Duration.ofSeconds(maxIdleTimeSeconds))
                .evictInBackground(Duration.ofSeconds(maxIdleTimeSeconds))
                .build();
    }

    /**
     * Costruisce l'HttpClient con responseTimeout.
     * Condiviso da tutti i @Bean WebClient di questa config.
     */
    private HttpClient buildHttpClient() {
        return HttpClient.create(psnConnectionProvider())
                .responseTimeout(Duration.ofSeconds(60));
    }

    /**
     * Filter: logga metodo HTTP + URL di ogni chiamata WebClient (livello INFO).
     * Decommentare il blocco DEBUG per vedere anche gli header.
     */
    private ExchangeFilterFunction webClientUrlFilter() {
        return ExchangeFilterFunction.ofRequestProcessor(request -> {
            log.info("[FILTER] Chiamata HTTP {} {}", request.method(), request.url());
            return Mono.just(request);
        });
    }

    /*
     * DEBUG — decommentare per loggare request/response in fase di sviluppo.
     * ATTENZIONE: può esporre dati sensibili in produzione, tenere commentato.
     *
     * private static ExchangeFilterFunction logRequest() {
     *     return ExchangeFilterFunction.ofRequestProcessor(request -> {
     *         log.debug("➡️  {} {}", request.method(), request.url());
     *         return Mono.just(request);
     *     });
     * }
     *
     * private static ExchangeFilterFunction logResponse() {
     *     return ExchangeFilterFunction.ofResponseProcessor(response -> {
     *         log.debug("⬅️  HTTP {}", response.statusCode());
     *         return Mono.just(response);
     *     });
     * }
     *
     * // Header completi (SOLO dev — espone token/credenziali)
     * public static ExchangeFilterFunction logHeaders() {
     *     return ExchangeFilterFunction.ofRequestProcessor(request -> {
     *         var sb = new StringBuilder("--- REQUEST HEADERS ---\n");
     *         sb.append("Method: ").append(request.method()).append("\n");
     *         sb.append("URL   : ").append(request.url()).append("\n");
     *         sb.append("Headers:\n");
     *         request.headers().forEach((name, values) -> values.forEach(value ->
     *             sb.append("  ").append(name).append(": ").append(value).append("\n")));
     *         sb.append("---------------------------------------\n");
     *         log.info(sb.toString());
     *         return Mono.just(request);
     *     });
     * }
     */

    /**
     * Bean di esempio — TODO: RENAME con il nome della tua prima API esterna.
     * Mostra il pattern minimo per un client HTTP verso un'API JSON.
     */
    @Bean(name = "exampleApiClient")
    public WebClient exampleApiClient() {
        return WebClient.builder()
                .clientConnector(new ReactorClientHttpConnector(buildHttpClient()))
                // TODO: RENAME — sostituisci con il baseUrl della tua API
                // .baseUrl(exampleApiBaseUrl)
                .defaultHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                .filter(webClientUrlFilter())
                .build();
    }
}
