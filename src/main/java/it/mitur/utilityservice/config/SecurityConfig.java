package it.mitur.utilityservice.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;

/**
 * Security configuration — OWASP Top 10 baseline.
 *
 * A01 – Access Control  : Actuator /actuator/** bloccato salvo health/info.
 *                         Swagger permesso. TODO: aggiungere JWT/OAuth2.
 * A05 – Misconfiguration: Security headers HTTP abilitati (HSTS, CSP, X-Frame, nosniff).
 * A07 – Auth Failures   : Session stateless, no HTTP Basic default.
 */
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            // REST API stateless: nessuna sessione, nessun CSRF cookie
            .csrf(AbstractHttpConfigurer::disable)
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))

            // ── OWASP A05: Security Headers ──────────────────────────────────
            .headers(headers -> headers
                // HSTS: forza HTTPS per 1 anno inclusi subdomini
                .httpStrictTransportSecurity(hsts -> hsts
                    .includeSubDomains(true)
                    .maxAgeInSeconds(31_536_000))
                // Impedisce clickjacking
                .frameOptions(frame -> frame.deny())
                // Impedisce MIME sniffing
                .contentTypeOptions(ct -> {})
                // Content Security Policy
                .contentSecurityPolicy(csp -> csp
                    .policyDirectives("default-src 'self'; frame-ancestors 'none'"))
                // Referrer Policy
                .referrerPolicy(ref -> ref
                    .policy(org.springframework.security.web.header.writers.ReferrerPolicyHeaderWriter.ReferrerPolicy.NO_REFERRER))
            )

            // ── OWASP A01: Access Control ─────────────────────────────────────
            .authorizeHttpRequests(auth -> auth
                // Actuator: solo health e info pubblici
                .requestMatchers("/actuator/health", "/actuator/info").permitAll()
                // Tutti gli altri endpoint actuator bloccati
                .requestMatchers("/actuator/**").denyAll()
                // Swagger UI
                .requestMatchers(
                    "/swagger-ui/**",
                    "/swagger-ui.html",
                    "/v3/api-docs/**"
                ).permitAll()
                // TODO: sostituire con autenticazione JWT/OAuth2 per i tuoi endpoint
                .anyRequest().permitAll()
            );

        return http.build();
    }
}
