# JAXB — Abilitare la generazione di classi da XSD

JAXB è **disabilitato per default**. Abilitarlo solo se il tuo package usa schemi XSD per la serializzazione XML.

---

## 1. Aggiungi i tuoi XSD

Copia i file `.xsd` in:

```
src/main/resources/xsd/
```

---

## 2. Abilita le dipendenze in pom.xml

Decommentare nel blocco `<dependencies>`:

```xml
<dependency>
    <groupId>jakarta.xml.bind</groupId>
    <artifactId>jakarta.xml.bind-api</artifactId>
</dependency>
<dependency>
    <groupId>org.glassfish.jaxb</groupId>
    <artifactId>jaxb-runtime</artifactId>
</dependency>
```

---

## 3. Abilita il plugin in pom.xml

Decommentare nel blocco `<build><plugins>`:

```xml
<!-- jaxb-maven-plugin — già presente commentato nel pom.xml -->
```

Il plugin è preconfigurato per leggere da `src/main/resources/xsd/` e scrivere in
`target/generated-sources/jaxb/` (auto-discovered da Maven — nessun plugin aggiuntivo necessario).

---

## 4. Imposta il package di destinazione

Nel blocco `<configuration>` del plugin, aggiorna:

```xml
<packageName>it.mitur.{tuo-package}.generated</packageName>
```

---

## 5. Genera le classi

```bash
mvn generate-sources
```

Le classi appaiono in `target/generated-sources/jaxb/` e sono disponibili alla compilazione.

---

## Regole

- Usa sempre `jakarta.xml.bind.*` — **mai** `javax.xml.bind.*` (incompatibile con Java 17+)
- Non committare `target/generated-sources/` — viene rigenerato ad ogni build
- Non editare manualmente le classi generate — sono sovrascritte da `mvn generate-sources`
- Non aggiungere `build-helper-maven-plugin` — `target/generated-sources/` è auto-discovered da Maven
