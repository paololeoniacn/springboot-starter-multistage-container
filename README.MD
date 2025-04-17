### ✅ `README.md`

```markdown
# Utility Service

Microservizio Spring Boot di utilità generale, sviluppato per il progetto MiTur.

## 🚀 Come avviare il servizio

### Prerequisiti

- [Podman](https://podman.io/) installato e avviato (oppure Podman Desktop)
- Java 17
- Maven

---

### 🔧 Avvio tramite script (consigliato)

#### Windows (PowerShell)

```powershell
.\build-and-run.ps1
```

#### Linux/macOS (Bash)

```bash
./build-and-run.sh
```

---

### 🔍 Endpoint disponibile

Una volta avviata l'applicazione, puoi testare l'endpoint:

```
GET http://localhost:8080/hello
```

**Risposta attesa:**

```
Hello World
```

---

### 🛠 Struttura del progetto

```
utility-service/
├── src/
│   ├── main/
│   │   ├── java/it/mitur/utilityservice/
│   │   │   ├── controller/HelloWorldController.java
│   │   │   └── UtilityServiceApplication.java
│   │   └── resources/application.properties
├── Dockerfile
├── pom.xml
├── build-and-run.ps1
└── build-and-run.sh
```

---

### 🧹 Pulizia automatica

Gli script `build-and-run` rimuovono automaticamente:

- container precedenti con lo stesso nome
- immagini **dangling**
- container **exited**

---

### 🧪 Test

Per testare manualmente l'endpoint:

```bash
curl http://localhost:8080/hello
```

---

### 📦 Build manuale (senza script)

```bash
mvn clean package
podman build -t utility-service .
podman run -d --name utility-service-container -p 8080:8080 utility-service
```

