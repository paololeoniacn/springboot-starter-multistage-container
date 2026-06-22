# Project: springboot-starter-multistage-container

> Stato aggiornato del progetto: vedi **[SOA.md](SOA.md)**

## Stack
- Java 17, Spring Boot 3.4.4, Maven 3.9.9
- Containerization: Podman (preferred) or Docker — auto-detected by `handle_project.sh`
- JAXB: Jakarta EE (`jakarta.xml.bind`), plugin `org.jvnet.jaxb:jaxb-maven-plugin:4.0.9`

## Structure
```
src/main/java/it/mitur/utilityservice/
  controller/   REST controllers only — no DTOs here
  dto/          request/response DTOs
  generated/    do NOT edit — JAXB output (in target/, not src/)
src/main/resources/
  xsd/          XSD schemas → JAXB generates to target/generated-sources/jaxb/
```

## Rules
- DTOs go in `it.mitur.utilityservice.dto`, never in `controller`
- JAXB generated classes output to `target/generated-sources/jaxb/` — never commit, never edit manually
- `jabx/` is gitignored and obsolete — ignore it
- Never add `javax.xml.bind.*` — always `jakarta.xml.bind.*`
- Never add `build-helper-maven-plugin` — `target/generated-sources/` is auto-discovered by Maven

## Build & Run
```bash
./handle_project.sh deploy   # build image + run container
./handle_project.sh start    # start without rebuild
./handle_project.sh logs     # follow logs
./handle_project.sh status   # health check
./handle_project.sh help     # all commands
```

Local Maven build (no container):
```bash
mvn clean package -DskipTests
```

## Endpoints (port 8080)
- `GET /hello` — smoke test
- `GET /actuator/health` — health check
- `GET /swagger-ui.html` — API docs

## Dockerfile
3-stage multistage build:
1. `deps` — `maven:3.9.9-eclipse-temurin-17`, caches Maven deps (invalidated only on pom.xml change)
2. `build` — copies `src/`, runs `mvn clean package -DskipTests`
3. `runtime` — `eclipse-temurin:17-jre-jammy`, non-root user `appuser`

## Adding a new XSD
1. Add `.xsd` to `src/main/resources/xsd/`
2. Add `<include>newfile.xsd</include>` in `pom.xml` under `jaxb-maven-plugin`
3. Run `mvn generate-sources` — classes appear in `target/generated-sources/jaxb/`
