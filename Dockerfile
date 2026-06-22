# ------------ Stage 1: Cache dipendenze Maven ------------
# Rebuild solo se pom.xml cambia
FROM maven:3.9.9-eclipse-temurin-17 AS deps

WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -B --no-transfer-progress


# ------------ Stage 2: Build ------------
# Rebuild solo se src/ cambia
FROM deps AS build

COPY src ./src
RUN mvn clean package -DskipTests -B --no-transfer-progress


# ------------ Stage 3: Runtime ------------
FROM eclipse-temurin:17-jre-jammy AS runtime

WORKDIR /app

# Utente non-root
RUN groupadd --system appgroup && \
    useradd --system --gid appgroup --no-create-home appuser
USER appuser

COPY --from=build /app/target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
