Perfetto Paolo, partiamo dal tuo **punto zero**:  
✅ Hai un **file `.xsd`** (come `putRequest.xsd`)  
🎯 Vuoi scrivere un **controller Spring Boot** che:
- Accetta XML
- Valida rispetto all’XSD
- Swagger mostra i campi
- Funziona in modo semplice e pulito (KIS)

---

## 🧩 Step-by-step — da XSD a Controller funzionante

---

### ✅ **1. Metti il tuo `.xsd` in:**
```
src/main/resources/xsd/putRequest.xsd
```

---

### ✅ **2. Configura il `pom.xml` per generare i DTO da XSD**

Aggiungi nel `<build><plugins>`:

```xml
<plugin>
  <groupId>org.codehaus.mojo</groupId>
  <artifactId>jaxb2-maven-plugin</artifactId>
  <version>2.5.0</version>
  <executions>
    <execution>
      <id>xjc</id>
      <goals>
        <goal>xjc</goal>
      </goals>
    </execution>
  </executions>
  <configuration>
    <sources>
      <source>src/main/resources/xsd/putRequest.xsd</source>
    </sources>
    <outputDirectory>${project.basedir}/jabx</outputDirectory>
    <packageName>com.example.generated</packageName>
  </configuration>
</plugin>

<!-- Per dire a Maven che jabx/ è una source folder -->
<plugin>
  <groupId>org.codehaus.mojo</groupId>
  <artifactId>build-helper-maven-plugin</artifactId>
  <version>3.2.0</version>
  <executions>
    <execution>
      <id>add-jabx</id>
      <phase>generate-sources</phase>
      <goals><goal>add-source</goal></goals>
      <configuration>
        <sources>
          <source>${project.basedir}/jabx</source>
        </sources>
      </configuration>
    </execution>
  </executions>
</plugin>
```

---

### ✅ **3. Aggiungi le dipendenze JAXB per Java 17+**

Nel blocco `<dependencies>`:

```xml
<dependency>
  <groupId>javax.xml.bind</groupId>
  <artifactId>jaxb-api</artifactId>
  <version>2.3.1</version>
</dependency>

<dependency>
  <groupId>org.glassfish.jaxb</groupId>
  <artifactId>jaxb-runtime</artifactId>
  <version>2.3.3</version>
</dependency>
```

📝 **Non usare Jakarta JAXB se i tuoi file generati usano `javax.xml.bind`!**

---

### ✅ **4. Genera le classi DTO**

```bash
mvn clean compile
```

Troverai le classi generate in `jabx/com/example/generated/`

---

### ✅ **5. Crea una classe wrapper con `@XmlRootElement`**

Nel tuo progetto (es: `src/main/java/it/mitur/wrapper/Consents.java`):

```java
package it.mitur.wrapper;

import com.example.generated.ConsentsType;

import javax.xml.bind.annotation.XmlRootElement;

@XmlRootElement(name = "consents")
public class Consents extends ConsentsType {
    // niente da fare, erediti tutto
}
```

---

### ✅ **6. Crea il controller che accetta XML**

```java
package it.mitur.controller;

import it.mitur.wrapper.Consents;

import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/consents")
public class ConsentsController {

    @PostMapping(consumes = MediaType.APPLICATION_XML_VALUE)
    public ResponseEntity<String> ricevi(@RequestBody Consents consents) {
        return ResponseEntity.ok("Ricevuto consents: " + consents.toString());
    }
}
```

---

### ✅ **7. Testa con Swagger o Postman**

#### Esempio XML da inviare:
```xml
<consents xmlns="http://www.example.com/schema">
    <!-- campi secondo lo schema -->
</consents>
```

---

### ✅ **8. (Opzionale) Configura Swagger**

Se non lo hai ancora:

```xml
<dependency>
  <groupId>org.springdoc</groupId>
  <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
  <version>2.2.0</version>
</dependency>
```

Apri:  
`http://localhost:8080/swagger-ui.html`
