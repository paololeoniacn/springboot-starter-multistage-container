# Project: springboot-starter-multistage-container

> Stato aggiornato del progetto: vedi **[SOA.md](SOA.md)**

## Stack
- Java 17, Spring Boot 3.5.7, Maven 3.9.9
- Logging: Log4j2 API → SLF4J → Logback (via `log4j-to-slf4j`)
- Containerization: Podman/Docker — `handle_project.sh` (Mac/Linux), `handle_project.ps1` (Windows)
- JAXB: **commentato per default** — vedi README-XSD.md per abilitarlo

## Structure
```
src/main/java/it/mitur/starter/
  StarterApplication.java           # TODO: RENAME
  config/
    SecurityConfig.java             # OWASP baseline — pronto all'uso
    JacksonDuplicateKeysConfig.java # pronto all'uso
    SingleValueQueryParamFilter.java # pronto all'uso
    S3Config.java                   # pronto all'uso
    WebClientConfig.java            # TODO: RENAME i bean WebClient
  controller/
    HelloWorldController.java       # TODO: RENAME con i tuoi controller
  dto/common/
    ErrorResponse.java              # pronto all'uso
    S3Request.java                  # pronto all'uso
  entity/
    AppInPut.java                   # TODO: RENAME classe e tabella DB
    AppActivityLog.java             # TODO: RENAME classe e tabella DB
    AnagParameter.java              # pronto all'uso (tabella condivisa)
  exception/
    GlobalExceptionHandler.java     # pronto all'uso
  repository/
    AppInPutRepository.java         # TODO: RENAME
    AppActivityLogRepository.java   # TODO: RENAME
    AnagParameterRepository.java    # pronto all'uso
  service/utils/
    AuditHelper.java                # TODO: RENAME entità e s3-path-prefix
    PostgresService.java            # TODO: RENAME entità
    S3Service.java                  # pronto all'uso
  utils/
    LogUtil.java                    # pronto all'uso

src/main/resources/
  logback-spring.xml                # configurazione logging unificata
  application.properties            # base comune (env vars per segreti)
  application-local.properties      # sviluppo locale
  application-docker.properties     # compose locale
  application-prod.properties       # produzione PSN
  xsd/                              # XSD opzionali (JAXB disabilitato per default)

src/test/java/it/mitur/starter/
  HelloWorldControllerTest.java     # TODO: RENAME
src/test/resources/
  application-test.properties       # H2 in-memory + stub AWS per CI
```

## Rules
- DTOs in `it.mitur.starter.dto`, mai nei controller
- Usa `LogUtil.error(log, msg, e)` per gli errori nei `@Service` — niente `e.printStackTrace()`, niente stacktrace a ERROR
- `AuditHelper` orchestra S3 + PostgreSQL: usare per ogni richiesta/risposta che richiede audit trail
- Entità JPA template (`AppInPut`, `AppActivityLog`) vanno rinominate (classe + tabella) prima di usarle
- `AnagParameter` e `AnagParameterRepository` sono pronti all'uso (tabella condivisa tra package)
- `logback-spring.xml` gestisce automaticamente il livello per profilo: DEV/STAGE → INFO, PROD → ERROR
- Tutte le credenziali da env vars — mai hardcoded in application.properties o sorgenti
- JAXB: classi generate in `target/generated-sources/jaxb/` — mai committare, mai editare manualmente
- Mai `javax.xml.bind.*` — sempre `jakarta.xml.bind.*`
- Mai `build-helper-maven-plugin` — `target/generated-sources/` è auto-discovered da Maven

## Build & Run

**Mac/Linux:**
```bash
cp .env.example .env               # valorizza le variabili d'ambiente
./handle_project.sh init           # inizializza il progetto (una volta sola)
./handle_project.sh deploy         # build + run
./handle_project.sh logs           # follow logs
./handle_project.sh status         # health check
./handle_project.sh help           # tutti i comandi
```

**Windows (Podman/Docker):**
```powershell
.\handle_project.ps1 deploy
.\handle_project.ps1 help
```

**Maven locale (senza container):**
```bash
mvn clean package -DskipTests
mvn test -Dspring.profiles.active=test   # CI senza PostgreSQL/AWS
```

## Endpoints (port 8080)
- `GET /hello` — smoke test (TODO: RENAME/rimuovere)
- `GET /actuator/health` — health check (liveness/readiness probe)
- `GET /swagger-ui.html` — API docs

## Profili Spring
| Profilo | Log Level | Actuator esposto | Attivato da |
|---|---|---|---|
| DEV | INFO | tutto | `env=DEV` in .env |
| STAGE | INFO | tutto | `env=STAGE` |
| PROD | ERROR | health, info | `env=PROD` |
| docker | INFO | health, info | compose.yaml |
| test | INFO | — | `@ActiveProfiles("test")` |

## JAXB (opzionale)
Commentato per default: nessuno dei package MiTur di produzione usa JAXB.
Per abilitarlo: decommentare le dipendenze e il plugin `jaxb-maven-plugin` in `pom.xml`,
poi eseguire `mvn generate-sources`. Vedi `README-XSD.md` per i dettagli.
