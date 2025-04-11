# ------------ Fase 1: Build ------------
FROM maven:3.9.5-eclipse-temurin-17 AS build

# Crea directory di lavoro
WORKDIR /app

# Copia i file di progetto e scarica dipendenze
COPY pom.xml .
COPY src ./src

# Compila il progetto senza eseguire i test
RUN mvn clean package -DskipTests


# ------------ Fase 2: Runtime ------------
FROM eclipse-temurin:17-jre

# Crea directory di lavoro
WORKDIR /app

# Copia il JAR costruito nella fase precedente
COPY --from=build /app/target/*.jar app.jar

# Espone la porta standard di Spring Boot
EXPOSE 8080

# Comando per avviare l'applicazione
ENTRYPOINT ["java", "-jar", "app.jar"]
