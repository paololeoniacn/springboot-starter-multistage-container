package it.mitur.starter;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Smoke test — verifica che il contesto Spring si avvii correttamente e
 * che l'endpoint /hello risponda 200 "Hello World".
 *
 * Usa il profilo "test" (application-test.properties) che configura:
 *   - H2 in-memory al posto di PostgreSQL
 *   - Credenziali AWS stub (nessuna connessione reale a S3)
 *
 * TODO: RENAME — dopo aver rinominato StarterApplication, aggiorna questo test.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class HelloWorldControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void testHelloWorldEndpoint() throws Exception {
        mockMvc.perform(get("/hello"))
               .andExpect(status().isOk())
               .andExpect(content().string("Hello World"));
    }
}
