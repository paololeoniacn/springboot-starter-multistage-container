package it.mitur.starter.config;

import java.io.IOException;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * Rifiuta le richieste su /api/** con query parameter duplicati.
 *
 * Pronto all'uso — nessun TODO: RENAME necessario.
 *
 * Es.: GET /api/resource?id=1&id=2 → 400 Bad Request
 * (il nome del parametro non viene esposto nel messaggio di errore)
 *
 * Property: mitur.params.reject-duplicates=true (default in application.properties)
 */
@Component
@Order(Ordered.HIGHEST_PRECEDENCE + 10)
public class SingleValueQueryParamFilter extends OncePerRequestFilter {

    @Value("${mitur.params.reject-duplicates:true}")
    private boolean reject;

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res,
            FilterChain chain)
            throws ServletException, IOException {
        if (reject && req.getRequestURI().startsWith("/api/")) {
            for (Map.Entry<String, String[]> e : req.getParameterMap().entrySet()) {
                String[] vals = e.getValue();
                if (vals != null && vals.length > 1) {
                    // Non esponiamo il nome del parametro nella risposta di errore
                    res.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    res.setContentType("application/json");
                    res.getWriter().write("{\"errorCode\":400,\"message\":\"Richiesta non valida.\"}");
                    return;
                }
            }
        }
        chain.doFilter(req, res);
    }
}
