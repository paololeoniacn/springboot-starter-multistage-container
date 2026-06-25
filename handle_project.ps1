# =============================================================================
# handle_project.ps1 — MiTur Starter project manager (Windows)
# =============================================================================
# Uso: .\handle_project.ps1 <comando>
#
# Comandi:
#   init      Inizializza il progetto (sostituisce i placeholder — una volta sola)
#   build     Build immagine (Podman o Docker, rilevato automaticamente)
#   deploy    Build + avvio container (full redeploy)
#   start     Avvia container senza rebuild
#   stop      Ferma il container
#   restart   Stop + start
#   logs      Log in tempo reale (CTRL+C per uscire)
#   status    Stato container + health check
#   shell     Shell nel container
#   clean     Rimuovi immagini dangling + container exited
#   reset     Stop + rimozione immagine + clean totale (con conferma)
#   help      Mostra questo messaggio
# =============================================================================

param(
    [Parameter(Position = 0)]
    [string]$Command = "help"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Configurazione ─────────────────────────────────────────────────────────────
# TODO: RENAME — init aggiorna IMAGE_NAME automaticamente; se usi deploy/start
#       senza init, aggiorna questo valore manualmente.
$IMAGE_NAME     = "mitur-starter"
$CONTAINER_NAME = "$IMAGE_NAME-container"
$PORT           = 8080
$HEALTH_URL     = "http://localhost:$PORT/actuator/health"
$APP_URL        = "http://localhost:$PORT"

# ── Rilevamento tool container ─────────────────────────────────────────────────
function Detect-Tool {
    if (Get-Command podman -ErrorAction SilentlyContinue) {
        try { podman info 2>$null | Out-Null; return "podman" } catch {}
    }
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        try { docker info 2>$null | Out-Null; return "docker" } catch {}
    }
    return $null
}

$TOOL = Detect-Tool

function Assert-Tool {
    if (-not $TOOL) {
        Write-Host "❌ Ne' podman ne' docker trovati o attivi." -ForegroundColor Red
        Write-Host "   Installa Podman Desktop: https://podman-desktop.io" -ForegroundColor Gray
        exit 1
    }
    Write-Host "   Container tool: $TOOL" -ForegroundColor DarkCyan
}

# ── Helpers container ──────────────────────────────────────────────────────────
function Container-Exists {
    $names = & $TOOL ps -a --format "{{.Names}}" 2>$null
    return ($names -split "`n") -contains $CONTAINER_NAME
}

function Container-Running {
    $names = & $TOOL ps --format "{{.Names}}" 2>$null
    return ($names -split "`n") -contains $CONTAINER_NAME
}

function Image-Exists {
    & $TOOL image inspect $IMAGE_NAME 2>$null | Out-Null
    return $LASTEXITCODE -eq 0
}

function Wait-Healthy {
    Write-Host ""
    Write-Host "⏳ Attendo avvio applicazione..." -ForegroundColor Cyan
    $max = 30
    for ($i = 0; $i -lt $max; $i++) {
        try {
            $r = Invoke-WebRequest -Uri $HEALTH_URL -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
            if ($r.StatusCode -eq 200) {
                Write-Host "✅ Applicazione UP!" -ForegroundColor Green
                return
            }
        } catch {}
        Start-Sleep -Seconds 2
        Write-Host -NoNewline "."
    }
    Write-Host ""
    Write-Host "⚠️  Health check timeout. Il container potrebbe ancora avviarsi." -ForegroundColor Yellow
}

function Print-Urls {
    Write-Host ""
    Write-Host "📡 Endpoints:" -ForegroundColor White
    Write-Host "   Hello World : $APP_URL/hello"         -ForegroundColor Cyan
    Write-Host "   Swagger UI  : $APP_URL/swagger-ui.html" -ForegroundColor Cyan
    Write-Host "   Health      : $HEALTH_URL"            -ForegroundColor Cyan
    Write-Host "   Actuator    : $APP_URL/actuator"      -ForegroundColor Cyan
}

# ── Helpers init ───────────────────────────────────────────────────────────────

# Chiede input con validazione regex; ripete finché il valore non è valido.
function Read-Validated {
    param(
        [string]$Prompt,
        [string]$Pattern,
        [string]$ErrorMsg,
        [string]$Default = ""
    )
    while ($true) {
        $displayPrompt = if ($Default) { "$Prompt [$Default]" } else { $Prompt }
        $value = Read-Host "  $displayPrompt"
        if ($value -eq "" -and $Default -ne "") { return $Default }
        if ($value -match $Pattern) { return $value }
        Write-Host "  ❌ $ErrorMsg" -ForegroundColor Red
    }
}

# Sostituisce il contenuto di un file preservando encoding UTF-8 senza BOM.
function Replace-InFile {
    param(
        [string]$FilePath,
        [hashtable]$Replacements  # ordered: chiave=pattern (regex), valore=sostituzione
    )
    try {
        $content = Get-Content $FilePath -Raw -Encoding UTF8
        if ($null -eq $content) { return }
        foreach ($entry in $Replacements.GetEnumerator()) {
            $content = $content -replace $entry.Key, $entry.Value
        }
        # Scrivi senza BOM (UTF-8 puro, compatibile con Linux/macOS)
        [System.IO.File]::WriteAllText($FilePath, $content, [System.Text.UTF8Encoding]::new($false))
    } catch {
        # File binario o non leggibile — ignora silenziosamente
    }
}

# Rimuove le directory vuote sotto un percorso radice dato.
function Remove-EmptyDirs {
    param([string]$Root)
    if (-not (Test-Path $Root)) { return }
    try {
        # Bottom-up: le sottodirectory prima della radice
        Get-ChildItem -Path $Root -Recurse -Directory -ErrorAction SilentlyContinue |
            Sort-Object FullName -Descending |
            ForEach-Object {
                if (@(Get-ChildItem $_.FullName -Force -ErrorAction SilentlyContinue).Count -eq 0) {
                    Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
                }
            }
        if (@(Get-ChildItem $Root -Force -ErrorAction SilentlyContinue).Count -eq 0) {
            Remove-Item $Root -Force -ErrorAction SilentlyContinue
        }
    } catch {
        # Cleanup non critico — ignorato silenziosamente
    }
}

# ── Cmd-Init ──────────────────────────────────────────────────────────────────
function Cmd-Init {
    # Verifica che il placeholder sia ancora presente
    if (-not (Test-Path "pom.xml") -or
        -not (Select-String -Path "pom.xml" -Pattern "mitur-starter" -Quiet)) {
        Write-Host ""
        Write-Host "⚠️  Placeholder 'mitur-starter' non trovato in pom.xml." -ForegroundColor Yellow
        Write-Host "   Progetto gia' inizializzato, o non sei nella root del progetto." -ForegroundColor Gray
        exit 1
    }

    Write-Host ""
    Write-Host "🚀 Inizializzazione nuovo progetto MiTur" -ForegroundColor White
    Write-Host "────────────────────────────────────────"
    Write-Host "  Sostituisce i placeholder 'mitur-starter' con i valori del tuo package."
    Write-Host "  Eseguire UNA SOLA VOLTA dopo il clone."
    Write-Host ""

    # 1. Nome progetto (kebab-case)
    $appName = Read-Validated `
        -Prompt "Nome progetto (kebab-case, es. myapp, web-service)" `
        -Pattern "^[a-z][a-z0-9-]+$" `
        -ErrorMsg "Solo minuscole, numeri e trattini. Es: myapp, my-service"

    # 2. Group ID
    $groupId = Read-Validated `
        -Prompt "Group ID (es. it.mitur)" `
        -Pattern "^[a-z][a-z0-9]+(\.[a-z][a-z0-9]+)+$" `
        -ErrorMsg "Formato: it.mitur, com.example, etc."

    # 3. Descrizione (opzionale)
    $appDesc = Read-Host "  Descrizione [$appName]"
    if ($appDesc -eq "") { $appDesc = $appName }

    # 4. Prefisso tabelle DB (es. myd_ → myd_in_put, myd_activity_log)
    $defaultPrefix = ($appName -replace "-", "_").Substring(0, [Math]::Min(3, $appName.Length)) + "_"
    $dbPrefix = Read-Validated `
        -Prompt "Prefisso tabelle DB" `
        -Pattern "^[a-z][a-z0-9_]*_$" `
        -ErrorMsg "Deve terminare con _ Es: myd_, abc_, svc_" `
        -Default $defaultPrefix

    # Valori derivati
    $javaAppSeg  = ($appName -replace "-", "").ToLower()         # es. myapp, webservice
    $javaPkg     = "$groupId.$javaAppSeg"                         # es. it.mitur.myapp
    $groupIdPath = $groupId -replace "\.", "/"                    # es. it/mitur
    $javaPkgPath = $javaPkg -replace "\.", "/"                    # es. it/mitur/myapp

    # Riepilogo
    Write-Host ""
    Write-Host "  Riepilogo:" -ForegroundColor White
    Write-Host "  App name    : $appName"    -ForegroundColor Cyan
    Write-Host "  Group ID    : $groupId"    -ForegroundColor Cyan
    Write-Host "  Java pkg    : $javaPkg"    -ForegroundColor Cyan
    Write-Host "  DB prefix   : $dbPrefix  (es: ${dbPrefix}in_put, ${dbPrefix}activity_log)" -ForegroundColor Cyan
    Write-Host "  S3 prefix   : internal/$appName" -ForegroundColor Cyan
    Write-Host "  Descrizione : $appDesc"   -ForegroundColor Cyan
    Write-Host ""

    $confirm = Read-Host "Confermi? [y/N]"
    if ($confirm -notmatch "^[Yy]$") {
        Write-Host "Annullato." -ForegroundColor Yellow
        return
    }

    Write-Host ""
    Write-Host "⚙️  Applicazione modifiche..." -ForegroundColor White

    # Mappa di sostituzioni regex — ordine critico: più specifico prima.
    # Le chiavi sono pattern regex; i valori sono literal replacement.
    # PowerShell -replace: il pattern è regex, il replacement NON lo è
    # (ma $1, $2 sono interpretati come backreference — qui non usiamo catture).
    $replacements = [ordered]@{
        # 1. Package Java completo (es. it.mitur.starter → it.mitur.myapp)
        'it\.mitur\.starter'   = $javaPkg
        'it/mitur/starter'     = $javaPkgPath
        # 2. Group ID (es. it.mitur → it.mitur, no-op se stesso; o it.example)
        'it\.mitur'            = $groupId
        'it/mitur'             = $groupIdPath
        # 3. App name (es. mitur-starter → myapp)
        'mitur-starter'        = $appName
        # 4. Tabelle DB template
        'app_in_put'           = "${dbPrefix}in_put"
        'app_activity_log'     = "${dbPrefix}activity_log"
        # 5. Path S3 audit
        'internal/starter'     = "internal/$appName"
    }

    # File da processare (stesse estensioni dello script bash)
    $extensions = @("*.java","*.xml","*.properties","*.yml","*.yaml","*.sh","*.ps1","*.md","*.sql","*.json")
    $files = Get-ChildItem -Path . -Recurse -File -Include $extensions |
        Where-Object {
            $_.FullName -notmatch [regex]::Escape("\.git") -and
            $_.FullName -notmatch [regex]::Escape("\target\") -and
            $_.FullName -notmatch [regex]::Escape("\jabx\")
        }

    $count = 0
    foreach ($file in $files) {
        Replace-InFile -FilePath $file.FullName -Replacements $replacements
        $count++
    }

    Write-Host "   $count file processati." -ForegroundColor Gray

    # ── Rinomina directory Java sorgenti ──────────────────────────────────────
    $newMainPath = "src\main\java\$($javaPkgPath -replace '/', '\')"
    $oldMainPath = "src\main\java\it\mitur\starter"

    if (Test-Path $oldMainPath) {
        $newMainParent = Split-Path $newMainPath -Parent
        New-Item -ItemType Directory -Force -Path $newMainParent | Out-Null
        Move-Item -Path $oldMainPath -Destination $newMainPath -Force
        Write-Host "   main: $oldMainPath -> $newMainPath" -ForegroundColor Gray
        Remove-EmptyDirs -Root "src\main\java\it\mitur"
    }

    $newTestPath = "src\test\java\$($javaPkgPath -replace '/', '\')"
    $oldTestPath = "src\test\java\it\mitur\starter"

    if (Test-Path $oldTestPath) {
        $newTestParent = Split-Path $newTestPath -Parent
        New-Item -ItemType Directory -Force -Path $newTestParent | Out-Null
        Move-Item -Path $oldTestPath -Destination $newTestPath -Force
        Write-Host "   test: $oldTestPath -> $newTestPath" -ForegroundColor Gray
        Remove-EmptyDirs -Root "src\test\java\it\mitur"
    }

    # ── Cleanup boilerplate docs + README di progetto ────────────────────────────
    Remove-Item -Path "SOA.md"                            -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "README-XSD.md"                     -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "dependency-check-suppressions.xml" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path ".gitattributes"                    -Force -ErrorAction SilentlyContinue

    $readmeContent = @'
# __APP_NAME__

Microservizio Spring Boot — progetto MiTur/PSN.

## Prerequisiti

- Java 17 / Maven 3.9.9
- Podman o Docker installato e avviato

## Avvio (consigliato)

**Windows (PowerShell):**
```powershell
.\handle_project.ps1 deploy
```

**Mac/Linux (Bash):**
```bash
./handle_project.sh deploy
```

## Comandi

| Comando  | Descrizione                |
|----------|----------------------------|
| `deploy` | Build + avvio container    |
| `logs`   | Follow log del container   |
| `status` | Health check               |
| `help`   | Tutti i comandi            |

## Endpoint

- `GET /hello` — smoke test (rimuovere dopo sviluppo iniziale)
- `GET /actuator/health` — health check (liveness/readiness probe)
- `GET /swagger-ui.html` — API docs

## Struttura del progetto

```
src/main/java/__JAVA_PKG__/
  ...Application.java
  config/
  controller/
  dto/
  entity/
  exception/
  repository/
  service/utils/
  utils/
```

## Build Maven

```bash
mvn clean package -DskipTests
mvn test -Dspring.profiles.active=test
```

## Variabili d'ambiente

Copia `.env.example` in `.env` e valorizza:

- `AWS_*` — credenziali S3
- `POSTGRES_*` — credenziali database
- `ENV` — profilo attivo (`DEV` / `STAGE` / `PROD`)

> `.env` non viene committato. Usa `.env.example` come riferimento per il team.
'@
    $readmeContent = $readmeContent -replace '__APP_NAME__', $appName
    $readmeContent = $readmeContent -replace '__JAVA_PKG__', ($javaPkgPath -replace '\\', '/')
    [System.IO.File]::WriteAllText("README.MD", $readmeContent, [System.Text.UTF8Encoding]::new($false))
    Write-Host "   SOA.md, README-XSD.md: rimossi"              -ForegroundColor Gray
    Write-Host "   README.MD: aggiornato al template di progetto" -ForegroundColor Gray

    # ── Riepilogo finale ──────────────────────────────────────────────────────
    Write-Host ""
    Write-Host "✅ Progetto inizializzato come '$appName'" -ForegroundColor Green
    Write-Host "   Java package : $javaPkg"         -ForegroundColor Cyan
    Write-Host "   DB prefix    : $dbPrefix"         -ForegroundColor Cyan
    Write-Host "   S3 prefix    : internal/$appName" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "⚠️  TODO: RENAME — completa manualmente i rinomi guidati dai commenti" -ForegroundColor Yellow
    Write-Host "       nelle sorgenti (StarterApplication → tua classe, AppInPut → tua entita', ecc.)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   Verifica build : mvn clean package -DskipTests" -ForegroundColor White
    Write-Host "   Avvia          : .\handle_project.ps1 deploy"   -ForegroundColor White
    Write-Host ""
    Write-Host "💡 Riavvia questo script per usare il nuovo IMAGE_NAME." -ForegroundColor Yellow
}

# ── Cmd-Build ──────────────────────────────────────────────────────────────────
function Cmd-Build {
    Assert-Tool
    Write-Host ""
    Write-Host "🔨 Build immagine: $IMAGE_NAME" -ForegroundColor White
    & $TOOL build -t $IMAGE_NAME .
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Build fallita." -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Build completata." -ForegroundColor Green
}

# ── Cmd-Start ──────────────────────────────────────────────────────────────────
function Cmd-Start {
    Assert-Tool
    if (Container-Running) {
        Write-Host "⚠️  Container gia' in esecuzione." -ForegroundColor Yellow
        Print-Urls
        return
    }
    if (Container-Exists) {
        Write-Host ""
        Write-Host "🔄 Avvio container esistente..."
        & $TOOL start $CONTAINER_NAME
    } else {
        if (-not (Image-Exists)) {
            Write-Host "⚠️  Immagine non trovata. Eseguo build prima..." -ForegroundColor Yellow
            Cmd-Build
        }
        Write-Host ""
        Write-Host "🚀 Avvio container sulla porta $PORT..."
        $envFileArg = if (Test-Path ".env") { @("--env-file", ".env") } else { @() }
        & $TOOL run -d --name $CONTAINER_NAME -p "${PORT}:8080" `
            @envFileArg `
            -e SPRING_PROFILES_ACTIVE=docker `
            $IMAGE_NAME
    }
    Wait-Healthy
    Print-Urls
}

# ── Cmd-Deploy ─────────────────────────────────────────────────────────────────
function Cmd-Deploy {
    Assert-Tool
    Cmd-Build
    if (Container-Exists) {
        Write-Host ""
        Write-Host "🧹 Rimozione container precedente..."
        & $TOOL rm -f $CONTAINER_NAME
    }
    Write-Host ""
    Write-Host "🚀 Avvio container sulla porta $PORT..."
    $envFileArg = if (Test-Path ".env") { @("--env-file", ".env") } else { @() }
    & $TOOL run -d --name $CONTAINER_NAME -p "${PORT}:8080" `
        @envFileArg `
        -e SPRING_PROFILES_ACTIVE=docker `
        $IMAGE_NAME
    Wait-Healthy
    Print-Urls
}

# ── Cmd-Stop ───────────────────────────────────────────────────────────────────
function Cmd-Stop {
    Assert-Tool
    if (-not (Container-Running)) {
        Write-Host "⚠️  Nessun container in esecuzione." -ForegroundColor Yellow
        return
    }
    Write-Host ""
    Write-Host "🛑 Stop container $CONTAINER_NAME..."
    & $TOOL stop $CONTAINER_NAME
    Write-Host "✅ Container fermato." -ForegroundColor Green
}

# ── Cmd-Restart ────────────────────────────────────────────────────────────────
function Cmd-Restart {
    try { Cmd-Stop } catch {}
    Cmd-Start
}

# ── Cmd-Logs ───────────────────────────────────────────────────────────────────
function Cmd-Logs {
    Assert-Tool
    if (-not (Container-Running)) {
        Write-Host "❌ Container non in esecuzione." -ForegroundColor Red
        exit 1
    }
    Write-Host "📺 Log in tempo reale — CTRL+C per uscire"
    Write-Host ""
    & $TOOL logs -f $CONTAINER_NAME
}

# ── Cmd-Status ─────────────────────────────────────────────────────────────────
function Cmd-Status {
    Assert-Tool
    Write-Host ""
    Write-Host "📊 Status: $IMAGE_NAME" -ForegroundColor White
    Write-Host "─────────────────────────────────────"

    if (Container-Running) {
        Write-Host "Container : " -NoNewline
        Write-Host "● running" -ForegroundColor Green

        $started = & $TOOL inspect $CONTAINER_NAME --format "{{.State.StartedAt}}" 2>$null
        Write-Host "Avviato   : $started"

        Write-Host -NoNewline "Health    : "
        try {
            $r = Invoke-WebRequest -Uri $HEALTH_URL -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
            $json = $r.Content | ConvertFrom-Json
            Write-Host $json.status -ForegroundColor Green
        } catch {
            Write-Host "unreachable" -ForegroundColor Yellow
        }
        Print-Urls
    } elseif (Container-Exists) {
        Write-Host "Container : " -NoNewline
        Write-Host "● stopped" -ForegroundColor Yellow
    } else {
        Write-Host "Container : " -NoNewline
        Write-Host "● non esiste" -ForegroundColor Red
    }

    Write-Host ""
    if (Image-Exists) {
        $imgId = & $TOOL image inspect $IMAGE_NAME --format "{{.Id}}" 2>$null
        Write-Host "Immagine  : $imgId"
    } else {
        Write-Host "Immagine  : " -NoNewline
        Write-Host "non trovata" -ForegroundColor Red
    }
    Write-Host ""
}

# ── Cmd-Shell ──────────────────────────────────────────────────────────────────
function Cmd-Shell {
    Assert-Tool
    if (-not (Container-Running)) {
        Write-Host "❌ Container non in esecuzione." -ForegroundColor Red
        exit 1
    }
    Write-Host "🐚 Shell nel container $CONTAINER_NAME..."
    & $TOOL exec -it $CONTAINER_NAME /bin/bash
    if ($LASTEXITCODE -ne 0) {
        & $TOOL exec -it $CONTAINER_NAME /bin/sh
    }
}

# ── Cmd-Clean ──────────────────────────────────────────────────────────────────
function Cmd-Clean {
    Assert-Tool
    Write-Host ""
    Write-Host "🧹 Pulizia immagini dangling..."
    $imgs = & $TOOL images -f "dangling=true" -q 2>$null
    if ($imgs) {
        $imgs | ForEach-Object { & $TOOL rmi $_ | Out-Null }
        Write-Host "🧼 Immagini dangling rimosse." -ForegroundColor Green
    } else {
        Write-Host "   Nessuna immagine dangling."
    }
    Write-Host ""
    Write-Host "🧹 Pulizia container exited..."
    $conts = & $TOOL ps -a -f "status=exited" -q 2>$null
    if ($conts) {
        $conts | ForEach-Object { & $TOOL rm $_ | Out-Null }
        Write-Host "🧼 Container exited rimossi." -ForegroundColor Green
    } else {
        Write-Host "   Nessun container exited."
    }
}

# ── Cmd-Reset ──────────────────────────────────────────────────────────────────
function Cmd-Reset {
    Assert-Tool
    Write-Host "⚠️  Reset completo: stop + rimozione container + immagine + clean" -ForegroundColor Yellow
    $confirm = Read-Host "Confermi? [y/N]"
    if ($confirm -notmatch "^[Yy]$") {
        Write-Host "Annullato." -ForegroundColor Gray
        return
    }
    try { & $TOOL rm -f $CONTAINER_NAME 2>$null } catch {}
    try { & $TOOL rmi -f $IMAGE_NAME 2>$null }    catch {}
    Cmd-Clean
    Write-Host "✅ Reset completato." -ForegroundColor Green
}

# ── Cmd-Help ───────────────────────────────────────────────────────────────────
function Cmd-Help {
    Write-Host ""
    Write-Host "handle_project.ps1 — MiTur Starter project manager (Windows)" -ForegroundColor White
    Write-Host ""
    Write-Host "USO" -ForegroundColor White
    Write-Host "  .\handle_project.ps1 <comando>"
    Write-Host ""
    Write-Host "COMANDI" -ForegroundColor White
    Write-Host "  init     " -NoNewline -ForegroundColor Cyan
    Write-Host "Inizializza il progetto (sostituisce placeholder — una volta sola)"
    Write-Host "  build    " -NoNewline -ForegroundColor Cyan
    Write-Host "Build immagine (multistage Dockerfile)"
    Write-Host "  deploy   " -NoNewline -ForegroundColor Cyan
    Write-Host "Build + avvio container (full redeploy)"
    Write-Host "  start    " -NoNewline -ForegroundColor Cyan
    Write-Host "Avvia container senza rebuild"
    Write-Host "  stop     " -NoNewline -ForegroundColor Cyan
    Write-Host "Ferma il container"
    Write-Host "  restart  " -NoNewline -ForegroundColor Cyan
    Write-Host "Stop + start"
    Write-Host "  logs     " -NoNewline -ForegroundColor Cyan
    Write-Host "Log in tempo reale (CTRL+C per uscire)"
    Write-Host "  status   " -NoNewline -ForegroundColor Cyan
    Write-Host "Stato container + health check"
    Write-Host "  shell    " -NoNewline -ForegroundColor Cyan
    Write-Host "Shell nel container"
    Write-Host "  clean    " -NoNewline -ForegroundColor Cyan
    Write-Host "Rimuovi immagini dangling + container exited"
    Write-Host "  reset    " -NoNewline -ForegroundColor Cyan
    Write-Host "Stop + rm container + rm immagine + clean (con conferma)"
    Write-Host "  help     " -NoNewline -ForegroundColor Cyan
    Write-Host "Questo messaggio"
    Write-Host ""
    Write-Host "WORKFLOW NUOVO PROGETTO" -ForegroundColor White
    Write-Host "  git clone <repo> <my-project>; cd <my-project>"
    Write-Host "  Copy-Item .env.example .env  # valorizza .env con i tuoi segreti"
    Write-Host "  .\handle_project.ps1 init    # configura nome, groupId, DB prefix"
    Write-Host "  mvn clean package -DskipTests"
    Write-Host "  .\handle_project.ps1 deploy"
    Write-Host ""
    Write-Host "TEST IN CI (senza infrastruttura)" -ForegroundColor White
    Write-Host "  mvn test -Dspring.profiles.active=test"
    Write-Host ""
    Write-Host "NOTA" -ForegroundColor White
    Write-Host "  Se PowerShell blocca l'esecuzione degli script:"
    Write-Host "  Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned"
    Write-Host "  Rilevamento automatico: usa Podman se disponibile, altrimenti Docker."
    Write-Host ""
}

# ── Entrypoint ─────────────────────────────────────────────────────────────────
switch ($Command.ToLower()) {
    "init"    { Cmd-Init    }
    "build"   { Cmd-Build   }
    "deploy"  { Cmd-Deploy  }
    "start"   { Cmd-Start   }
    "stop"    { Cmd-Stop    }
    "restart" { Cmd-Restart }
    "logs"    { Cmd-Logs    }
    "status"  { Cmd-Status  }
    "shell"   { Cmd-Shell   }
    "clean"   { Cmd-Clean   }
    "reset"   { Cmd-Reset   }
    "help"    { Cmd-Help    }
    default {
        Write-Host "❌ Comando sconosciuto: $Command" -ForegroundColor Red
        Cmd-Help
        exit 1
    }
}
