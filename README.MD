# MiTur Starter — Spring Boot Boilerplate

Template production-ready per i package del progetto MiTur/PSN.
Clona questa repo, esegui `init`, e trovi già posizionati i pattern comuni tra i package MiTur di produzione.

---

## Indice

1. [Scopo e contesto](#1-scopo-e-contesto)
2. [Quick Start](#2-quick-start)
3. [Struttura del progetto](#3-struttura-del-progetto)
4. [Componenti pronti all'uso](#4-componenti-pronti-alluso)
5. [Cosa rinominare — TODO list](#5-cosa-rinominare--todo-list)
6. [Profili Spring](#6-profili-spring)
7. [Pattern AuditHelper](#7-pattern-audithelper)
8. [Logging con LogUtil](#8-logging-con-logutil)
9. [WebClient — chiamate API esterne](#9-webclient--chiamate-api-esterne)
10. [Database — PostgreSQL e tabelle](#10-database--postgresql-e-tabelle)
11. [Sicurezza OWASP](#11-sicurezza-owasp)
12. [Test in CI](#12-test-in-ci)
13. [JAXB (opzionale)](#13-jaxb-opzionale)
14. [OWASP Dependency Check](#14-owasp-dependency-check)
15. [File di root](#15-file-di-root)

---

## 1. Scopo e contesto

Ogni nuovo package MiTur replica manualmente gli stessi pattern: logging sicuro, audit trail S3+PostgreSQL, configurazione AWS, sicurezza OWASP, gestione errori HTTP, WebClient con connection pool PSN. Farlo a mano porta a inconsistenze tra package e a lavoro duplicato.

Questo boilerplate cristallizza la versione più matura di quei pattern in un punto solo. Chi clona trova già:

- la struttura di directory coerente con i package di produzione
- i componenti pronti all'uso (LogUtil, AuditHelper, S3Service, SecurityConfig, ...)
- le entità e i service template da rinominare con i nomi del proprio dominio
- pom.xml con le dipendenze allineate alla produzione (Spring Boot 3.5.7, AWS SDK v2, ...)
- script di deploy per Mac/Linux (`handle_project.sh`) e Windows (`handle_project.ps1`)

**Cosa non è**: un'applicazione funzionante. È un template da rinominare e specializzare.

---

## 2. Quick Start

### Mac / Linux

```bash
# 1. Clone
git clone <repo-url> my-new-package && cd my-new-package

# 2. Variabili d'ambiente
cp .env.example .env
# Modifica .env con AWS_*, POSTGRES_*, ENV=DEV

# 3. Inizializza (una volta sola — sostituisce tutti i placeholder)
./handle_project.sh init
# → chiede: nome progetto (es. myapp), groupId (es. it.mitur), prefisso DB (es. myapp_)
# → aggiorna package Java, tabelle DB, S3 path, pom.xml, scripts

# 4. Completa i TODO: RENAME nei sorgenti (sezione 5)

# 5. Verifica build
mvn clean package -DskipTests

# 6. Avvia
./handle_project.sh deploy
```

### Windows (PowerShell)

```powershell
# 1. Clone
git clone <repo-url> my-new-package; cd my-new-package

# 2. Variabili d'ambiente
Copy-Item .env.example .env
# Modifica .env con i valori reali

# 3. Inizializza
.\handle_project.ps1 init

# 4. Verifica build
mvn clean package -DskipTests

# 5. Avvia
.\handle_project.ps1 deploy
```

> Prima esecuzione PS1: `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned`

**Verifica**: `GET http://localhost:8080/actuator/health` → `{"status":"UP"}`

**Test CI** (senza PostgreSQL né AWS): `mvn test -Dspring.profiles.active=test`

---

## 3. Struttura del progetto

```
springboot-starter-multistage-container/
├── src/
│   ├── main/
│   │   ├── java/it/mitur/starter/
│   │   │   ├── StarterApplication.java          ← TODO: RENAME
│   │   │   ├── config/
│   │   │   │   ├── SecurityConfig.java           ← OWASP baseline
│   │   │   │   ├── JacksonDuplicateKeysConfig.java
│   │   │   │   ├── SingleValueQueryParamFilter.java
│   │   │   │   ├── S3Config.java
│   │   │   │   └── WebClientConfig.java          ← TODO: aggiungi i tuoi bean
│   │   │   ├── controller/
│   │   │   │   └── HelloWorldController.java     ← TODO: RENAME/sostituisci
│   │   │   ├── dto/common/
│   │   │   │   ├── ErrorResponse.java
│   │   │   │   └── S3Request.java
│   │   │   ├── entity/
│   │   │   │   ├── AppInPut.java                 ← TODO: RENAME
│   │   │   │   ├── AppActivityLog.java            ← TODO: RENAME
│   │   │   │   └── AnagParameter.java             ← pronto all'uso
│   │   │   ├── exception/
│   │   │   │   └── GlobalExceptionHandler.java
│   │   │   ├── repository/
│   │   │   │   ├── AppInPutRepository.java       ← TODO: RENAME
│   │   │   │   ├── AppActivityLogRepository.java ← TODO: RENAME
│   │   │   │   └── AnagParameterRepository.java  ← pronto all'uso
│   │   │   ├── service/utils/
│   │   │   │   ├── AuditHelper.java              ← TODO: RENAME entità
│   │   │   │   ├── PostgresService.java          ← TODO: RENAME entità
│   │   │   │   └── S3Service.java                ← pronto all'uso
│   │   │   └── utils/
│   │   │       └── LogUtil.java                  ← pronto all'uso
│   │   └── resources/
│   │       ├── logback-spring.xml                ← logging unificato
│   │       ├── application.properties            ← base comune
│   │       ├── application-local.properties      ← sviluppo locale
│   │       ├── application-docker.properties     ← compose locale
│   │       ├── application-prod.properties       ← produzione PSN
│   │       └── xsd/                              ← XSD di riferimento
│   └── test/
│       ├── java/it/mitur/starter/
│       │   └── HelloWorldControllerTest.java
│       └── resources/
│           └── application-test.properties       ← H2 + stub AWS
├── .env.example                                  ← template variabili locali
├── Dockerfile                                    ← 3-stage multistage
├── compose.yaml                                  ← dev locale + PostgreSQL opz.
├── handle_project.sh                             ← CLI Mac/Linux
├── handle_project.ps1                            ← CLI Windows
└── pom.xml
```

---

## 4. Componenti pronti all'uso

Questi file funzionano senza modifiche dopo `init` (il package viene aggiornato automaticamente):

| Componente | File | Note |
|---|---|---|
| **Logging sicuro** | `utils/LogUtil.java` | ERROR senza stacktrace; prefisso ❌; comportamento configurabile per env |
| **Config S3** | `config/S3Config.java` | Bean `s3Client()` da env vars |
| **Upload S3** | `service/utils/S3Service.java` | Pattern a 3 file: `.json` + backup + `.trg` |
| **Sicurezza OWASP** | `config/SecurityConfig.java` | HSTS, CSP, X-Frame-Options, nosniff, sessione stateless |
| **Anti-injection JSON** | `config/JacksonDuplicateKeysConfig.java` | Chiavi JSON duplicate → 400 |
| **Anti-injection params** | `config/SingleValueQueryParamFilter.java` | Query param duplicati su `/api/**` → 400 |
| **Errori standard** | `dto/common/ErrorResponse.java` | `{errorCode, message}` — coerente tra tutti i package |
| **S3 DTO** | `dto/common/S3Request.java` | `{pathS3, jsonString}` |
| **Tabella parametri** | `entity/AnagParameter.java` | Configurazione runtime condivisa tra package |
| **Repository parametri** | `repository/AnagParameterRepository.java` | 3 query pronte: per flow, tipo, chiave |
| **Exception handler** | `exception/GlobalExceptionHandler.java` | 5 handler + catch-all; messaggi generici (no leak interni) |
| **Logging config** | `resources/logback-spring.xml` | Profile-aware, timestamp Roma, override via property |
| **Test CI** | `test/resources/application-test.properties` | H2 in-memory + stub AWS — no infrastruttura reale |
| **GitHub Actions** | `.github/workflows/build.yml` | Build + OWASP dependency check separato |
| **Dockerfile** | `Dockerfile` | 3-stage multistage, utente non-root |
| **Script CLI** | `handle_project.sh` / `handle_project.ps1` | init / build / deploy / logs / status / shell / clean / reset |

---

## 5. Cosa rinominare — TODO list

`init` sostituisce automaticamente il package Java (`it.mitur.starter → it.mitur.tuopackage`), il nome immagine, le tabelle DB (`app_in_put → {prefix}_in_put`), il path S3, l'artifactId nel `pom.xml`.

I rinomi **manuali** rimasti (guidati dai commenti `// TODO: RENAME` nei sorgenti):

| Cosa | File | Operazione |
|---|---|---|
| Classe applicazione | `StarterApplication.java` | Rinomina classe e file → es. `MyDomainApplication.java` |
| Entità richiesta | `entity/AppInPut.java` | Rinomina classe (es. `MyDomainInPut`) + `@Table(name="{prefix}_in_put")` |
| Entità log | `entity/AppActivityLog.java` | Rinomina classe (es. `MyDomainActivityLog`) + `@Table(name="{prefix}_activity_log")` |
| Repository entità | `repository/AppInPutRepository.java` | Rinomina file + aggiorna tipo generico |
| Repository log | `repository/AppActivityLogRepository.java` | Rinomina file + aggiorna tipo generico |
| Tipi service | `service/utils/PostgresService.java` | Sostituisci `AppInPut` con il tuo tipo |
| Tipi service | `service/utils/AuditHelper.java` | Sostituisci `AppInPut` con il tuo tipo |
| Path S3 | `application.properties` | Controlla `mitur.audit.s3-path-prefix` (già aggiornato da init) |
| Bean WebClient | `config/WebClientConfig.java` | Aggiungi i tuoi bean per le API esterne |
| Controller | `controller/HelloWorldController.java` | Sostituisci con i tuoi controller di dominio |
| Annotazioni main | `StarterApplication.java` | Aggiungi `@EnableAsync`, `@EnableScheduling`, `@EnableRetry` se necessarie |

**Hint**: trova tutti i punti da completare:

```bash
# Mac/Linux
grep -r "TODO: RENAME" src/

# Windows
Select-String -Path src -Pattern "TODO: RENAME" -Recurse
```

---

## 6. Profili Spring

L'ambiente è impostato dalla variabile `ENV` nel file `.env`, che viene letta da `spring.profiles.active`.

| Profilo | Log Level | Actuator esposto | Come si attiva |
|---|---|---|---|
| **DEV** | INFO | tutto (`*`) | `ENV=DEV` in `.env` — default locale |
| **STAGE** | INFO | tutto (`*`) | `ENV=STAGE` |
| **PROD** | ERROR | solo `health`, `info` | `ENV=PROD` |
| **docker** | INFO | `health`, `info` | `SPRING_PROFILES_ACTIVE=docker` in `compose.yaml` |
| **test** | INFO | — | `@ActiveProfiles("test")` nei test JUnit |

### Come funziona il livello di log

Il file `logback-spring.xml` usa i tag `<springProfile>` per impostare automaticamente il livello:
- `DEV` o `STAGE` → `ROOT=INFO`
- `PROD` → `ROOT=ERROR`

**Override temporaneo** (senza rebuild — utile per diagnostica rapida):
```properties
# Decommentare in application.properties, fare deploy, analizzare, ricommentare
# mitur.logging.root-level=DEBUG
```

---

## 7. Pattern AuditHelper

`AuditHelper` è il servizio che orchestra il ciclo di audit per ogni richiesta/risposta: serializza il JSON, lo carica su S3 con un path strutturato e scrive le righe di tracciamento su PostgreSQL.

### Flusso standard

```
[richiesta in arrivo]
       │
       ▼
auditHelper.logRequest(...)
       │  ├─ serializza requestObject → JSON
       │  ├─ upload S3: {prefix}/{service}/request/{id}/{ts}.json + .trg + backup
       │  └─ PostgreSQL: INSERT AppInPut (status="N") + INSERT AppActivityLog
       │
 [logica applicativa]
       │
       ├─ [successo] → auditHelper.logUpdate(... status="C" ...)
       │                  ├─ upload S3: .../response/{id}/{ts}.json + .trg
       │                  └─ UPDATE AppInPut + INSERT AppActivityLog
       │
       └─ [errore]   → auditHelper.logError(... status="E" ...)
                          └─ UPDATE AppInPut + INSERT AppActivityLog (niente S3)
```

### Esempio d'uso

```java
@Service
@RequiredArgsConstructor
public class MyService {

    private final AuditHelper auditHelper;
    private static final Logger log = LogManager.getLogger(MyService.class);
    private static final String SERVICE_NAME = "myService";  // = procName = idFlow

    public ResponseDto process(MyRequest request) throws Exception {

        // 1. Inizia audit — S3 upload request + DB init (status "N")
        AppInPut record = auditHelper.logRequest(SERVICE_NAME, request.getId(), request);

        try {
            // 2. Logica applicativa
            String responseJson = callExternalApi(request);

            // 3. Successo — S3 upload response + DB update "C"
            auditHelper.logUpdate(record, SERVICE_NAME, request.getId(),
                                  "C", "OK", null, responseJson);

            return deserialize(responseJson, ResponseDto.class);

        } catch (Exception e) {
            // 4. Errore — DB update "E" (nessun S3 upload)
            LogUtil.error(log, "Errore in " + SERVICE_NAME, e);
            auditHelper.logError(record, SERVICE_NAME, "E", "Errore API", e.getMessage());
            throw e;
        }
    }
}
```

### Struttura path S3

Con `mitur.audit.s3-path-prefix=internal/my-package` in `application.properties`:

```
internal/my-package/myService/request/ABC123/20240601T103045123.json   ← payload JSON
internal/my-package/myService/request/ABC123/20240601T103045123.trg    ← trigger (vuoto)
backup/20240601/internal/my-package/myService/request/ABC123/...json   ← backup
```

> **Sicurezza**: il JSON non viene mai loggato direttamente (potenziale PII). Nei log compare solo il path S3.

---

## 8. Logging con LogUtil

```java
// Dichiarazione — Log4j2 API (bridge → SLF4J → Logback tramite log4j-to-slf4j)
private static final Logger log = LogManager.getLogger(MyService.class);

// Uso nei catch
try {
    // ...
} catch (Exception e) {
    LogUtil.error(log, "Errore nel processo di sync", e);
}
```

### Comportamento per profilo

| Ambiente | Output ERROR | Stacktrace |
|---|---|---|
| **DEV / STAGE** | `❌ Errore nel processo di sync \| exception=Connection reset` | Solo a livello DEBUG |
| **PROD** (default) | `❌ Errore nel processo di sync` | No |
| **PROD + override** | `❌ Errore nel processo di sync \| exception=Connection reset` | No |

Il prefisso `❌` è visibile anche in log aggregati (Kibana, CloudWatch) senza filtri aggiuntivi.

### Regole

- Usa `LogUtil.error()` in tutti i `@Service` — mai `e.printStackTrace()` o `log.error("msg", e)` direttamente
- `GlobalExceptionHandler` usa SLF4J direttamente (è già il confine dell'applicazione, non c'è logica da tracciare)
- Il campo `%logger{36}` in logback mostra la **classe chiamante**, non `LogUtil`
- Overload SLF4J disponibile per Lombok `@Slf4j` (stessa firma, stesso comportamento)

### Override temporaneo per diagnostica in PROD

```properties
# In application.properties — decommentare, deploy, analizzare, ricommentare
# mitur.logging.include-exception-message=true
```

---

## 9. WebClient — chiamate API esterne

Il boilerplate usa Spring WebFlux **solo come client HTTP** (non come server reattivo).
`WebClientConfig` configura un connection pool condiviso (`psnConnectionProvider`) ottimizzato per il PSN.

### Perché un pool condiviso

- **maxIdleTime = 240s** < 330s (idle timeout PSN ~5.5 min): evita connessioni stale
- **responseTimeout = 60s**: impedisce che WebClient si blocchi indefinitamente se l'API non risponde — cruciale in produzione (senza di esso un'API down congela il thread fino al timeout TCP, che può essere minuti)

### Aggiungere un nuovo client API

```java
// In WebClientConfig.java

@Value("${mitur.api.myapi.base-url}")
private String myApiBaseUrl;

@Bean("myApiClient")
public WebClient myApiClient() {
    return WebClient.builder()
            .clientConnector(new ReactorClientHttpConnector(buildHttpClient()))
            .baseUrl(myApiBaseUrl)
            .defaultHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
            .filter(webClientUrlFilter())
            .build();
}
```

```properties
# In application.properties
mitur.api.myapi.base-url=${MY_API_BASE_URL}
```

```java
// Nel service che usa il client
@RequiredArgsConstructor
public class MyApiService {
    @Qualifier("myApiClient")
    private final WebClient myApiClient;

    public String call(String id) {
        return myApiClient.get()
                .uri("/endpoint/{id}", id)
                .retrieve()
                .bodyToMono(String.class)
                .block();  // blocco sincrono — nessuna reactive pipeline server-side
    }
}
```

### Debug chiamate HTTP

In `WebClientConfig.java` ci sono blocchi commentati per loggare request/response.
Decommentarli **solo in DEV** (possono esporre token e PII):

```java
// In WebClientConfig — già presenti come commenti
// logRequest()   → log.debug("➡️  {} {}", method, url)
// logResponse()  → log.debug("⬅️  HTTP {}", statusCode)
// logHeaders()   → stampa tutti gli header (SOLO dev, espone token)
```

---

## 10. Database — PostgreSQL e tabelle

### Struttura delle tabelle template

Ogni package MiTur usa due tabelle di audit più la tabella parametri condivisa:

| Tabella | Entity | Scopo |
|---|---|---|
| `{prefix}_in_put` | `AppInPut` → da rinominare | Una riga per richiesta (stato N/C/E, path S3 in/out) |
| `{prefix}_activity_log` | `AppActivityLog` → da rinominare | Append-only — un log per ogni passo del flusso |
| `anag_parameter` | `AnagParameter` → pronta | Configurazione runtime condivisa tra tutti i package |

### anag_parameter — configurazione runtime

Tabella chiave/valore per configurazioni che cambiano senza deploy (soglie, flag, URL, costanti):

```java
// Recupero di un parametro
Optional<AnagParameter> param = anagRepo.findByCdFlowAndCdTypeAndCdKey(
    "MY_FLOW", "CONFIG", "MAX_RETRY");
int maxRetry = Integer.parseInt(param.map(AnagParameter::getCdValue).orElse("3"));
```

### PostgresService — metodo unificato logActivity()

Il service espone un unico metodo append-only `logActivity()` invece di metodi separati per ogni tipo di operazione:

```java
// Init richiesta (risultato "N")
postgresService.logActivity(record.getId(), "init", "N", "Init", null, pathJsonIn);

// Passo intermedio
postgresService.logActivity(record.getId(), "callApi", "N", "Chiamata API", null, null);

// Completamento (risultato "C")
postgresService.logActivity(record.getId(), "done", "C", "OK", null, pathJsonOut);

// Errore (risultato "E")
postgresService.logActivity(record.getId(), "callApi", "E", "Timeout", e.getMessage(), null);
```

### Nota su ddl-auto

`spring.jpa.hibernate.ddl-auto=none` — le tabelle sono create e gestite **manualmente** (o via Flyway).
Non usare mai `create` o `update` in produzione.

---

## 11. Sicurezza OWASP

`SecurityConfig` implementa la baseline OWASP Top 10 per REST API:

| Header / Configurazione | Protezione |
|---|---|
| `Strict-Transport-Security` (1 anno, includeSubDomains) | A05 — forza HTTPS |
| `X-Frame-Options: DENY` | clickjacking |
| `X-Content-Type-Options: nosniff` | MIME sniffing |
| `Content-Security-Policy: default-src 'self'; frame-ancestors 'none'` | XSS, clickjacking |
| `Referrer-Policy: no-referrer` | privacy referrer |
| Sessione stateless, CSRF disabilitato | A07 — REST API |
| Actuator `/actuator/**` bloccato (solo `/health`, `/info` pubblici) | A01 |

`GlobalExceptionHandler` restituisce messaggi generici in 400 (no dettagli interni → A03).
`JacksonDuplicateKeysConfig` e `SingleValueQueryParamFilter` bloccano input malformati.

---

## 12. Test in CI

```bash
mvn test -Dspring.profiles.active=test
```

Il profilo `test` carica `src/test/resources/application-test.properties` che sovrascrive:
- **PostgreSQL** → H2 in-memory con `ddl-auto=create-drop`
- **AWS** → credenziali stub (`test` / `test-bucket`) — `S3Client` viene creato ma non si connette a S3

Nessuna infrastruttura esterna richiesta: funziona in GitHub Actions senza secrets.

### Isolare il test di un controller (senza DB e S3)

```java
@WebMvcTest(MyController.class)
@WithMockUser
class MyControllerTest {

    @Autowired MockMvc mockMvc;
    @MockBean  MyService myService;  // mock del service — nessun DB/S3

    @Test
    void testEndpoint() throws Exception {
        when(myService.process(any())).thenReturn("OK");
        mockMvc.perform(get("/api/my-endpoint"))
               .andExpect(status().isOk());
    }
}
```

### Mock S3Service nei test di integrazione

```java
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class MyServiceTest {
    @MockBean S3Service s3Service;  // evita le chiamate reali a S3
    // ...
}
```

---

## 13. JAXB (opzionale)

JAXB è **disabilitato per default**: non è necessario per la maggior parte dei package MiTur.
Gli XSD in `src/main/resources/xsd/` sono mantenuti come riferimento.

Per abilitarlo:
1. Decommentare le dipendenze `jakarta.xml.bind-api` e `jaxb-runtime` in `pom.xml`
2. Decommentare il plugin `jaxb-maven-plugin` in `pom.xml`
3. Aggiungere i propri XSD in `src/main/resources/xsd/`
4. Eseguire `mvn generate-sources`

Le classi generate appaiono in `target/generated-sources/jaxb/` — mai committare, mai editare.

Vedi [README-XSD.md](README-XSD.md) per i dettagli completi.

---

## 14. OWASP Dependency Check

Il plugin `dependency-check-maven` nel `pom.xml` fallisce la build se una dipendenza ha CVSS ≥ 7:

```bash
mvn dependency-check:check
```

- Falsi positivi verificati → aggiungere entry in `dependency-check-suppressions.xml`
- In CI: la scan gira in un job separato su push a `main` (è lenta — ~5 min)
- NVD API key → configurare `secrets.NVD_API_KEY` nel repo GitHub per velocizzarla

---

## 15. File di root

| File | Scopo |
|---|---|
| `pom.xml` | Dipendenze Maven + plugin (OWASP, spring-boot) + opzionali commentati |
| `Dockerfile` | Build multistage 3-stage: cache deps → build → runtime non-root |
| `compose.yaml` | Dev locale: container app + PostgreSQL opzionale commentato |
| `.env.example` | Template variabili d'ambiente — copiare in `.env` e valorizzare |
| `.gitignore` | `.env`, `target/`, IDE files |
| `handle_project.sh` | CLI Mac/Linux: init, build, deploy, start, stop, restart, logs, status, shell, clean, reset |
| `handle_project.ps1` | CLI Windows (parità funzionale con lo script bash, init incluso) |
| `CLAUDE.md` | Istruzioni per Claude Code (struttura, regole, build) |
| `SOA.md` | Stato del progetto — aggiornare ad ogni sessione significativa |
| `README-XSD.md` | Istruzioni per abilitare JAXB/XSD |
| `dependency-check-suppressions.xml` | Falsi positivi OWASP verificati |
