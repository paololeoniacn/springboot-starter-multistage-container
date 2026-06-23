# State of Affairs — MiTur Starter Boilerplate

## Versione corrente

Spring Boot 3.5.7 / Java 17 / Maven 3.9.9
Package base: `it.mitur.starter`
Ultimo aggiornamento: 2026-06-23

---

## Stato boilerplate

### Stack e infrastruttura
- Spring Boot 3.5.7, Java 17, Maven 3.9.9
- AWS SDK v2 BOM — gestisce versioni S3/STS/SQS
- PostgreSQL + HikariCP (pool size=5, idle=300s, max-lifetime=1800s)
- Spring WebFlux — solo WebClient, non server reattivo
- Podman/Docker — multistage Dockerfile, compose con `.env`

### Logging
- `logback-spring.xml` — profilo DEV/STAGE=INFO, PROD=ERROR; override via `mitur.logging.root-level`
- `LogUtil.java` — centralizza ERROR senza stacktrace in produzione; prefisso ❌ per scanning visivo
- Ponte Log4j2 API → SLF4J → Logback (`log4j-to-slf4j`)

### Audit trail
- `AuditHelper.java` — orchestra S3 + PostgreSQL per ogni ciclo richiesta/risposta
  - Logga SOLO il path S3, mai il contenuto JSON (no PII nei log)
  - Path S3 configurabile via `mitur.audit.s3-path-prefix`
- `PostgresService.java` — pattern `logActivity()` unificato, append-only
- `S3Service.java` — upload a 3 file: `.json` + backup + `.trg`
- `AppInPut.java`, `AppActivityLog.java` — entità template (TODO: RENAME per ogni package)
- `AnagParameter.java` — tabella di configurazione runtime condivisa

### Sicurezza e validazione
- `SecurityConfig.java` — OWASP baseline: HSTS, CSP, X-Frame, nosniff, stateless, CSRF off
- `JacksonDuplicateKeysConfig.java` — rifiuta JSON con chiavi duplicate → 400
- `SingleValueQueryParamFilter.java` — rifiuta query param duplicati su `/api/**` → 400
- `WebClientConfig.java` — connection pool PSN (240s idle < 330s timeout), responseTimeout(60s)
- `S3Config.java` — bean `s3Client()` generico da env vars
- `GlobalExceptionHandler.java` — usa `ErrorResponse(errorCode, message)` (no RFC 7807)

### Configurazione e deploy
- `application.properties` — tutte le sezioni: S3, PostgreSQL, HikariCP, WebClient, UTF-8
- Tutte le credenziali da env vars — mai hardcoded
- `application-test.properties` — H2 in-memory + stub AWS per CI senza infrastruttura
- `Dockerfile` — 3-stage multistage, ENTRYPOINT senza profilo hardcoded
- `compose.yaml` — `env_file: .env`, PostgreSQL commentato
- `handle_project.sh` / `handle_project.ps1` — CLI completa: init, build, deploy, logs, status, shell, clean, reset

### Test e CI
- `HelloWorldControllerTest` — `@SpringBootTest + @ActiveProfiles("test")` con H2
- GitHub Actions: build + test sul push; OWASP dependency check separato (non bloccante)

---

## TODO per il tuo package (post-clone)

Dopo `./handle_project.sh init` (o `.\handle_project.ps1 init`), completare manualmente i TODO: RENAME:

| File | Operazione |
|---|---|
| `StarterApplication.java` | Rinomina classe e file |
| `AppInPut.java` | Rinomina classe + tabella DB |
| `AppActivityLog.java` | Rinomina classe + tabella DB |
| `AppInPutRepository.java` | Rinomina + aggiorna tipo entità |
| `AppActivityLogRepository.java` | Rinomina + aggiorna tipo entità |
| `PostgresService.java` | Aggiorna tipi nelle firme |
| `AuditHelper.java` | Aggiorna tipo AppInPut |
| `WebClientConfig.java` | Aggiungi i tuoi bean WebClient reali |
| `application.properties` | Controlla `mitur.audit.s3-path-prefix` |
| `pom.xml` | Controlla groupId/artifactId post-init |
| `compose.yaml` | Rinomina service name se vuoi |

---

## Note architetturali

- `AnagParameter` è una tabella condivisa tra tutti i package MiTur — non rinominare
- `ddl-auto=none`: le tabelle sono gestite manualmente o via Flyway — mai auto-create in produzione
- HikariCP: pool size=5, idle=300s, max-lifetime=1800s
- WebClient: idle=240s < 330s PSN timeout, responseTimeout=60s — impedisce blocchi indefiniti su API irraggiungibili
- JAXB disabilitato per default — abilitare solo se il package usa XSD (vedi README-XSD.md)
