package it.mitur.utilityservice.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/avanzato")
public class AvanzatoController {

    // Endpoint con path, query, header e body insieme
    @PutMapping("/ordini/{ordineId}")
    public ResponseEntity<String> aggiornaOrdine(
            @PathVariable("ordineId") String ordineId,
            @RequestParam(name = "forza", defaultValue = "false") boolean forza,
            @RequestHeader(name = "X-User-Role", required = false) String ruolo,
            @RequestBody DettaglioOrdineDTO dettaglio
    ) {
        return ResponseEntity.ok("Ordine " + ordineId + " aggiornato con ruolo " + ruolo);
    }
}
