package it.mitur.utilityservice.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/test")
public class TestController {

    // GET con path variable e query param
    @GetMapping("/utente/{id}")
    public ResponseEntity<String> getUtenteById(
            @PathVariable("id") Long userId,
            @RequestParam(name = "verbose", required = false, defaultValue = "false") boolean verbose
    ) {
        return ResponseEntity.ok("Utente ID: " + userId + ", verbose: " + verbose);
    }

    // POST con request body
    @PostMapping("/utente")
    public ResponseEntity<UtenteDTO> creaUtente(@RequestBody UtenteDTO utente) {
        // Simulazione creazione
        utente.setId(100L);
        return ResponseEntity.status(201).body(utente);
    }
}
