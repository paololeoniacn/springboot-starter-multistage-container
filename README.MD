# MiTur Starter — Spring Boot Boilerplate

Template production-ready per i package del progetto MiTur/PSN.
Clona questa repo, esegui `init`, e trovi già posizionati i pattern comuni (logging sicuro, audit S3+PostgreSQL, sicurezza OWASP, WebClient PSN).

---

## Indice

1. [Prima di iniziare — 3 decisioni](#1-prima-di-iniziare--3-decisioni)
2. [Guida passo-passo — Creare un nuovo package](#2-guida-passo-passo--creare-un-nuovo-package)
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

## 1. Prima di iniziare — 3 decisioni

Decidi questi tre valori **prima** di partire — li userai durante lo `init`:

| Parametro | Cos'è | Esempio |
|---|---|---|
| **App name** | nome kebab-case del package | `tt49-webapp` |
| **Group ID** | group Maven, solitamente `it.mitur` | `it.mitur` |
| **Prefisso DB** | prefisso delle tabelle JPA (snake_case, con `_`) | `exp_` |

Il package Java viene derivato automaticamente: `it.mitur` + `tt49webapp` → `it.mitur.tt49webapp`.

---

## 2. Guida passo-passo — Creare un nuovo package

### Step 1 — Crea il repo di destinazione su GitLab (prima di tutto)

Crea il repo **vuoto** su GitLab (niente README, niente `.gitignore`).
Annotati l'URL che ti dà GitLab, ti serve al Step 4.

> Perché prima? Se cloni il boilerplate e poi non hai ancora il repo GitLab, non puoi fare il push finale.

---

### Step 2 — Clona il boilerplate sul branch corretto

```bash
git clone --branch claude_powered_silvio --single-branch \
  https://github.com/paololeoniacn/springboot-starter-multistage-container.git \
  nome-tuo-package
cd nome-tuo-package
```

Verifica di essere sul branch giusto:

```bash
git branch
# deve mostrare: * claude_powered_silvio
```

---

### Step 3 — Scollega il remote del boilerplate, aggancia il tuo

```bash
git remote remove origin
git remote add origin <URL-del-tuo-repo-GitLab>
git remote -v
```

Output atteso:

```
origin  http://localhost:8081/migrazione-tibco-be/nome-tuo-package.git (fetch)
origin  http://localhost:8081/migrazione-tibco-be/nome-tuo-package.git (push)
```

---

### Step 4 — Rinomina il branch in `main`

```bash
git branch -m claude_powered_silvio main
git branch
# deve mostrare: * main
```

---

### Step 5 — Prepara il file `.env`

**Mac/Linux:**
```bash
cp .env.example .env
```

**Windows:**
```powershell
Copy-Item .env.example .env
```

Apri `.env` e valorizza tutte le variabili:

```
ENV=DEV
AWS_REGION=eu-south-1
AWS_ACCESS_KEY=...
AWS_SECRET_KEY=...
AWS_BUCKET_NAME=...
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=mydb
POSTGRES_USER=myuser
POSTGRES_PASSWORD=...
POSTGRES_SCHEMA=public
```

> `.env` non viene mai committato (è in `.gitignore`). Usa `.env.example` come riferimento per il team.

---

### Step 6 — Esegui l'init

**Mac/Linux:**
```bash
chmod +x handle_project.sh
./handle_project.sh init
```

**Windows:**
```powershell
.\handle_project.ps1 init
```

Lo script chiede 4 valori. Rispondi usando i valori decisi al Step 1:

```
App name (kebab-case) [starter]:         tt49-webapp
Group ID               [it.mitur]:        it.mitur
DB prefix (snake_case) [app_]:            exp_
Descrizione            [tt49-webapp]:     TT49 WebApp
```

Output atteso (nessun errore):

```
[INIT] Avvio inizializzazione...
   Sostituzioni completate in N file
   main: src/main/java/it/mitur/starter -> src/main/java/it/mitur/tt49webapp
   test: src/test/java/it/mitur/starter -> src/test/java/it/mitur/tt49webapp
   SOA.md, README-XSD.md, dependency-check-suppressions.xml, .gitattributes: rimossi
   README.MD: aggiornato al template di progetto
[INIT] Completato.
```

---

### Step 7 — Verifica lo stato git

```bash
git status
```

Vedrai molti file `deleted:` e `untracked:`. **È tutto normale:**
- `deleted:` — le classi `starter` originali e i file boilerplate-only (`SOA.md`, `README-XSD.md`, `dependency-check-suppressions.xml`, `.gitattributes`)
- `modified:` — `README.MD` (aggiornato al template di progetto)
- `untracked:` — le nuove classi con il nome del tuo package

---

### Step 8 — Verifica la build Maven

```bash
mvn clean package -DskipTests
```

Deve terminare con `BUILD SUCCESS`. Se fallisce, controlla gli errori di compilazione prima di procedere.

---

### Step 9 — Completa i TODO: RENAME manuali

Lo script sostituisce automaticamente i placeholder nei file, ma alcune classi vanno rinominate a mano in base alla logica del tuo package.

Cerca tutti i punti aperti:

**Mac/Linux:**
```bash
grep -r "TODO: RENAME" src/
```

**Windows:**
```powershell
Select-String -Path src -Pattern "TODO: RENAME" -Recurse
```

Punti principali da completare:

| File | Cosa fare |
|---|---|
| `StarterApplication.java` | Rinomina classe e file |
| `AppInPut.java` | Rinomina classe + nome tabella JPA (`@Table`) |
| `AppActivityLog.java` | Rinomina classe + nome tabella JPA (`@Table`) |
| `AppInPutRepository.java` | Aggiorna tipo entità |
| `AppActivityLogRepository.java` | Aggiorna tipo entità |
| `PostgresService.java` | Aggiorna firme metodi con i tuoi tipi |
| `AuditHelper.java` | Aggiorna tipo entità + `mitur.audit.s3-path-prefix` |
| `WebClientConfig.java` | Aggiungi i tuoi bean WebClient reali |
| `application.properties` | `spring.application.name`, `mitur.audit.s3-path-prefix` |
| `HelloWorldController.java` | Rinomina o sostituisci con i tuoi controller |

---

### Step 10 — Prima commit e push

```bash
git add .
git status   # ricontrolla cosa stai committando
git commit -m "ADD :: init — nome-tuo-package inizializzato da boilerplate MiTur"
git push -u origin main
```

Se il push chiede credenziali, usa le tue credenziali GitLab (o il token personale se configurato).

---

## 3. Struttura del progetto

```
src/main/java/it/mitur/starter/
  StarterApplication.java           # TODO: RENAME
  config/
    SecurityConfig.java             # OWASP baseline — pronto all'uso
    JacksonDuplicateKeysConfig.java # blocca chiavi JSON duplicate
    SingleValueQueryParamFilter.java# blocca query param duplicati
    S3Config.java                   # bean S3Client configurato da .env
    WebClientConfig.java            # TODO: RENAME i bean WebClient
  controller/
    HelloWorldController.java       # TODO: RENAME con i tuoi controller
  dto/common/
    ErrorResponse.java              # risposta errore uniforme
    S3Request.java                  # path S3 + json payload
  entity/
    AppInPut.java                   # TODO: RENAME classe e tabella DB
    AppActivityLog.java             # TODO: RENAME classe e tabella DB
    AnagParameter.java              # tabella condivisa — pronto all'uso
  exception/
    GlobalExceptionHandler.java     # handler errori HTTP — pronto all'uso
  repository/
    AppInPutRepository.java         # TODO: RENAME
    AppActivityLogRepository.java   # TODO: RENAME
    AnagParameterRepository.java    # pronto all'uso
  service/utils/
    AuditHelper.java                # TODO: RENAME entità e s3-path-prefix
    PostgresService.java            # TODO: RENAME entità
    S3Service.java                  # upload/download S3 — pronto all'uso
  utils/
    LogUtil.java                    # wrapper logging sicuro — pronto all'uso

src/main/resources/
  logback-spring.xml                # logging per profilo (DEV INFO, PROD ERROR)
  application.properties            # configurazione base con env vars
  application-local.properties      # sviluppo locale
  application-docker.properties     # compose locale
  application-prod.properties       # produzione PSN
  .env.example                      # template variabili d'ambiente
  xsd/                              # XSD opzionali (JAXB disabilitato)

src/test/java/it/mitur/starter/
  HelloWorldControllerTest.java     # TODO: RENAME
src/test/resources/
  application-test.properties       # H2 in-memory + stub AWS per CI
```

---

## 4. Componenti pronti all'uso

| Componente | File | Note |
|---|---|---|
| Sicurezza OWASP | `SecurityConfig.java` | headers, CORS, CSRF — configurabile |
| Blocco JSON duplicati | `JacksonDuplicateKeysConfig.java` | property `mitur.json.reject-duplicate-keys` |
| Blocco param duplicati | `SingleValueQueryParamFilter.java` | property `mitur.params.reject-duplicates` |
| S3 Client | `S3Config.java` | configurato da env vars AWS_* |
| S3 Operations | `S3Service.java` | upload JSON + backup + trigger file |
| Audit trail | `AuditHelper.java` | S3 + PostgreSQL per ogni req/resp |
| Logging sicuro | `LogUtil.java` | no stacktrace in PROD, prefisso ❌ su ERROR |
| Errori HTTP | `GlobalExceptionHandler.java` + `ErrorResponse.java` | 400/401/500 uniformi |
| Tabella condivisa | `AnagParameter.java` + Repository | parametri di configurazione DB |
| Logging per profilo | `logback-spring.xml` | DEV/STAGE → INFO, PROD → ERROR |
| Test senza infra | `application-test.properties` | H2 in-memory, stub AWS |

---

## 5. Cosa rinominare — TODO list

Cerca con `grep -r "TODO: RENAME" src/` (Linux/Mac) o `Select-String -Path src -Pattern "TODO: RENAME" -Recurse` (Windows).

**Classi e tabelle JPA:**
- `AppInPut` → es. `CamInPut`, tabella `cam_in_put`
- `AppActivityLog` → es. `CamActivityLog`, tabella `cam_activity_log`
- Aggiorna anche Repository e le firme in `PostgresService` e `AuditHelper`

**Application:**
- `StarterApplication.java` → rinomina file e classe
- `HelloWorldController.java` → sostituisci con i tuoi controller reali

**Properties:**
- `spring.application.name` in `application.properties`
- `mitur.audit.s3-path-prefix` → es. `internal/cammini`

**WebClient:**
- `WebClientConfig.java`: aggiungi un bean per ogni API esterna che chiami (vedi commenti `// TODO: RENAME`)

---

## 6. Profili Spring

| Profilo | Log Level | Actuator esposto | Quando usarlo |
|---|---|---|---|
| `DEV` | INFO | tutto | sviluppo locale |
| `STAGE` | INFO | tutto | test pre-produzione |
| `PROD` | ERROR | health, info | produzione PSN |
| `docker` | INFO | health, info | compose locale |
| `test` | INFO | — | CI con H2 in-memory |

Attivato da `ENV=DEV` nel `.env` → `spring.profiles.active=${env}` in `application.properties`.

Override temporaneo log level (senza ricompilare):
```properties
# application-local.properties
mitur.logging.root-level=DEBUG
```

---

## 7. Pattern AuditHelper

Ogni richiesta/risposta che richiede audit trail segue questo ciclo:

```java
@Autowired AuditHelper auditHelper;

// 1. Ricezione richiesta
AppInPut record = auditHelper.logRequest("MyService", identifier, requestDto);

// 2. Chiamata API esterna / elaborazione
// ...

// 3. Salvataggio risposta
auditHelper.logUpdate(record, responseDto, "COMPLETED");

// 4. In caso di errore
auditHelper.logError(record, "Descrizione errore");
```

`AuditHelper` scrive su S3 (il JSON completo) e su PostgreSQL (riferimento al path S3).
Il contenuto JSON **non viene mai loggato** — solo il path S3 — per evitare PII nei log.

---

## 8. Logging con LogUtil

```java
private static final Logger log = LogUtil.getLogger(MyService.class);

log.info("elaborazione avviata per id={}", id);
LogUtil.error(log, "errore durante upload S3", exception);  // ❌ prefix automatico, no stacktrace in PROD
```

**Regola fondamentale:** usa sempre `LogUtil.error(log, msg, exception)` nei `@Service`, mai `e.printStackTrace()` o `log.error(..., e)` diretto.

In PROD: lo stacktrace non viene scritto a livello ERROR (evita flooding dei log PSN). Solo il messaggio.

---

## 9. WebClient — chiamate API esterne

`WebClientConfig` definisce un connection pool condiviso (`starterConnectionProvider`) con:
- idle timeout: 240s
- response timeout: 60s (evita blocchi indefiniti)

Aggiungi un bean per ogni API esterna:

```java
@Bean
public WebClient myExternalApiClient() {
    return buildHttpClient("https://api.example.com");  // TODO: RENAME
}
```

Il `webClientUrlFilter()` logga automaticamente metodo e URL di ogni chiamata.

---

## 10. Database — PostgreSQL e tabelle

Le tabelle JPA template:
- `app_in_put` — traccia ogni richiesta in ingresso (TODO: RENAME)
- `app_activity_log` — log append-only delle attività (TODO: RENAME)
- `anag_parameter` — parametri di configurazione condivisi (pronto all'uso)

**`ddl-auto=none`** — il boilerplate non crea tabelle automaticamente. Usa i tuoi script Liquibase/Flyway.

Schema configurabile: `spring.jpa.properties.hibernate.default_schema=${POSTGRES_SCHEMA}`.

---

## 11. Sicurezza OWASP

`SecurityConfig` applica di default:
- Content-Security-Policy
- X-Frame-Options: DENY
- X-Content-Type-Options: nosniff
- Referrer-Policy: no-referrer
- CSRF disabilitato per API REST stateless

**Credenziali:** mai hardcoded in `.properties` o sorgenti. Solo da env vars (`.env` → `${VAR}`).

**Validazione input:** usa `@Valid` + `@NotNull`/`@Size` sui DTO. `GlobalExceptionHandler` risponde 400 in modo uniforme.

---

## 12. Test in CI

```bash
mvn test -Dspring.profiles.active=test
```

`application-test.properties` configura:
- H2 in-memory (nessun PostgreSQL esterno)
- Stub AWS (credenziali fake — nessuna chiamata reale a S3)
- `ddl-auto=create-drop` (tabelle create e distrutte durante il test)

Tutti i test di `@SpringBootTest` girano senza infrastruttura esterna.

---

## 13. JAXB (opzionale)

JAXB è **disabilitato per default** — nessuno dei package MiTur di produzione lo usa.

Per abilitarlo, decommentare in `pom.xml`:
1. Le dipendenze `jakarta.xml.bind` e `jaxb-runtime`
2. Il plugin `jaxb-maven-plugin`

Poi eseguire `mvn generate-sources`. Vedi [README-XSD.md](README-XSD.md) per i dettagli completi.

**Nota:** usa sempre `jakarta.xml.bind.*`, mai `javax.xml.bind.*`.

---

## 14. OWASP Dependency Check

```bash
mvn dependency-check:check
```

Il plugin è già configurato in `pom.xml`. Fallisce la build su CVSS >= 7.
Soppressioni documentate in `dependency-check-suppressions.xml`.

---

## 15. File di root

| File | Descrizione |
|---|---|
| `handle_project.sh` | Gestione ciclo di vita (Mac/Linux): `init`, `deploy`, `logs`, `status`, `help` |
| `handle_project.ps1` | Stessa cosa su Windows (PowerShell) |
| `Dockerfile` | Multi-stage build: build Maven → runtime JRE slim |
| `compose.yaml` | Stack locale con container |
| `.env.example` | Template variabili d'ambiente — copia in `.env` e valorizza |
| `.gitignore` | Include `.env` (mai committare credenziali) |
| `CLAUDE.md` | Regole e struttura per Claude Code |
| `SOA.md` | Stato aggiornato del progetto e architettura |
| `README-XSD.md` | Guida JAXB opzionale |
| `dependency-check-suppressions.xml` | Soppressioni OWASP documentate |
