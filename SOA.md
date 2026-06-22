# State of Affairs

## Fatto

### Struttura base
- Spring Boot 3.4.4 / Java 17 / Maven 3.9.9
- Package layout: `controller/`, `dto/`, `generated/`
- DTOs separati dai controller
- `HelloWorldController`, `TestController`, `AvanzatoController` come esempi boilerplate

### JAXB (XSD → Java)
- Migrato da `javax.xml.bind` (legacy) a `jakarta.xml.bind` (Jakarta EE 9+)
- Plugin: `org.jvnet.jaxb:jaxb-maven-plugin:4.0.9`
- Output: `target/generated-sources/jaxb/it/mitur/utilityservice/generated/`
- XSD in `src/main/resources/xsd/putRequest.xsd`
- `jabx/` gitignored

### Container / Deploy
- Dockerfile multistage 3 stage (deps cache → build → runtime non-root)
- `compose.yaml` cross-platform (docker/podman)
- `handle_project.sh` — CLI unificata: build, deploy, start, stop, restart, logs, status, shell, clean, reset
- `build-and-run.sh` aggiornato (rimosso doppio build, auto-detect podman/docker)

### Infrastruttura
- Swagger/OpenAPI: `/swagger-ui.html`
- Actuator: `/actuator/health` e tutti gli endpoint esposti
- Logback configurato su STDOUT

---

## In corso / Prossimo step

### Database (PostgreSQL + Flyway)
- [ ] Ricevere dump PostgreSQL dall'utente (tabelle, enum, constraints)
- [ ] Aggiungere dipendenze: `spring-boot-starter-data-jpa`, `postgresql`, `flyway-core`
- [ ] Configurare `application.properties` con datasource (+ profilo `local` vs `docker`)
- [ ] Creare migration iniziale `V1__init.sql` da dump fornito
- [ ] Scrivere `@Entity` JPA a mano per le tabelle principali
- [ ] Aggiornare `compose.yaml` con servizio `postgres` + volume persistente
- [ ] Aggiornare `handle_project.sh` per gestire anche il db (wait-for-postgres, migrate)
- [ ] Aggiungere variabili d'ambiente DB nel Dockerfile/compose (non hardcoded)

### Test
- [ ] Aggiungere Testcontainers per integration test con PostgreSQL reale
- [ ] Test repository JPA base

### Da decidere
- [ ] Strategia profili Spring: `local` (H2 o Postgres locale), `docker` (Postgres in compose), `prod`
- [ ] Secret management (env var, Vault, o altro)

---

## Note architetturali
- Il boilerplate è pensato per essere clonato e adattato per ogni progetto MiTur
- Le tabelle del dump PostgreSQL sono condivise tra più progetti → le migration V1 saranno il "core schema"
- Le entity JPA vanno scritte a mano (no reverse engineering) per avere controllo totale
