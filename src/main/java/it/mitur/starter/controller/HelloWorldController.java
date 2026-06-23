package it.mitur.starter.controller;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Smoke-test endpoint — verifica che il container sia avviato e risponda.
 *
 * TODO: RENAME — sostituisci con i controller del tuo dominio.
 * Tieni questo endpoint solo durante lo sviluppo iniziale.
 *
 * Curl: GET http://localhost:8080/hello
 */
@RestController
public class HelloWorldController {

    private static final Logger logger = LogManager.getLogger(HelloWorldController.class);

    @GetMapping("/hello")
    public String helloWorld() {
        logger.info("Endpoint /hello chiamato.");
        return "Hello World";
    }
}
