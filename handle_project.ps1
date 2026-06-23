# =============================================================================
# HP.ps1 — Utility Service project manager (Windows + Podman)
# =============================================================================
# Uso: .\HP.ps1 <comando>
#
# Comandi:
#   build     Build immagine Podman (multistage Dockerfile)
#   deploy    Build + avvio container (full redeploy)
#   start     Avvia container senza rebuild
#   stop      Ferma il container
#   restart   Stop + start
#   logs      Log in tempo reale (CTRL+C per uscire)
#   status    Stato container + health check
#   shell     Shell nel container
#   clean     Rimuovi immagini dangling + container exited
#   reset     Stop + rimozione immagine + clean totale
#   help      Mostra questo messaggio
# =============================================================================

param(
    [Parameter(Position=0)]
    [string]$Command = "help"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Configurazione ────────────────────────────────────────────────────────────
$IMAGE_NAME     = "pl-generic-app-name"
$CONTAINER_NAME = "$IMAGE_NAME-container"
$PORT           = 8080
$HEALTH_URL     = "http://localhost:$PORT/actuator/health"
$APP_URL        = "http://localhost:$PORT"

# ── Helpers ───────────────────────────────────────────────────────────────────
function Check-Podman {
    if (-not (Get-Command podman -ErrorAction SilentlyContinue)) {
        Write-Host "❌ podman non trovato. Installa Podman Desktop: https://podman-desktop.io" -ForegroundColor Red
        exit 1
    }
    try {
        podman info | Out-Null
    } catch {
        Write-Host "❌ Podman non e' in esecuzione. Avvia Podman Desktop." -ForegroundColor Red
        exit 1
    }
}

function Container-Exists {
    $names = podman ps -a --format "{{.Names}}" 2>$null
    return ($names -split "`n") -contains $CONTAINER_NAME
}

function Container-Running {
    $names = podman ps --format "{{.Names}}" 2>$null
    return ($names -split "`n") -contains $CONTAINER_NAME
}

function Image-Exists {
    $result = podman image inspect $IMAGE_NAME 2>$null
    return $LASTEXITCODE -eq 0
}

function Wait-Healthy {
    Write-Host ""
    Write-Host "⏳ Attendo avvio applicazione..." -ForegroundColor Cyan
    $max = 30
    for ($i = 0; $i -lt $max; $i++) {
        try {
            $response = Invoke-WebRequest -Uri $HEALTH_URL -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
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
    Write-Host "   Hello World : $APP_URL/hello" -ForegroundColor Cyan
    Write-Host "   Swagger UI  : $APP_URL/swagger-ui.html" -ForegroundColor Cyan
    Write-Host "   Health      : $HEALTH_URL" -ForegroundColor Cyan
    Write-Host "   Actuator    : $APP_URL/actuator" -ForegroundColor Cyan
}

# ── Comandi ───────────────────────────────────────────────────────────────────
function Cmd-Build {
    Check-Podman
    Write-Host ""
    Write-Host "🔨 Build immagine: $IMAGE_NAME" -ForegroundColor White
    podman build -t $IMAGE_NAME .
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Build fallita." -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Build completata." -ForegroundColor Green
}

function Cmd-Start {
    Check-Podman
    if (Container-Running) {
        Write-Host "⚠️  Container gia' in esecuzione." -ForegroundColor Yellow
        Print-Urls
        return
    }
    if (Container-Exists) {
        Write-Host ""
        Write-Host "🔄 Avvio container esistente..."
        podman start $CONTAINER_NAME
    } else {
        if (-not (Image-Exists)) {
            Write-Host "⚠️  Immagine non trovata. Eseguo build prima..." -ForegroundColor Yellow
            Cmd-Build
        }
        Write-Host ""
        Write-Host "🚀 Avvio container sulla porta $PORT..."
        podman run -d --name $CONTAINER_NAME -p "${PORT}:8080" `
            -e SPRING_PROFILES_ACTIVE=docker `
            $IMAGE_NAME
    }
    Wait-Healthy
    Print-Urls
}

function Cmd-Deploy {
    Check-Podman
    Cmd-Build
    if (Container-Exists) {
        Write-Host ""
        Write-Host "🧹 Rimozione container precedente..."
        podman rm -f $CONTAINER_NAME
    }
    Write-Host ""
    Write-Host "🚀 Avvio container sulla porta $PORT..."
    podman run -d --name $CONTAINER_NAME -p "${PORT}:8080" `
        -e SPRING_PROFILES_ACTIVE=docker `
        $IMAGE_NAME
    Wait-Healthy
    Print-Urls
}

function Cmd-Stop {
    Check-Podman
    if (-not (Container-Running)) {
        Write-Host "⚠️  Nessun container in esecuzione." -ForegroundColor Yellow
        return
    }
    Write-Host ""
    Write-Host "🛑 Stop container $CONTAINER_NAME..."
    podman stop $CONTAINER_NAME
    Write-Host "✅ Container fermato." -ForegroundColor Green
}

function Cmd-Restart {
    Cmd-Stop
    Cmd-Start
}

function Cmd-Logs {
    Check-Podman
    if (-not (Container-Running)) {
        Write-Host "❌ Container non in esecuzione." -ForegroundColor Red
        exit 1
    }
    Write-Host "📺 Log in tempo reale — CTRL+C per uscire"
    Write-Host ""
    podman logs -f $CONTAINER_NAME
}

function Cmd-Status {
    Check-Podman
    Write-Host ""
    Write-Host "📊 Status: $IMAGE_NAME" -ForegroundColor White
    Write-Host "─────────────────────────────────────"

    if (Container-Running) {
        Write-Host "Container : " -NoNewline
        Write-Host "● running" -ForegroundColor Green

        $started = podman inspect $CONTAINER_NAME --format "{{.State.StartedAt}}" 2>$null
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
        $imgId = podman image inspect $IMAGE_NAME --format "{{.Id}}" 2>$null
        Write-Host "Immagine  : $imgId"
    } else {
        Write-Host "Immagine  : " -NoNewline
        Write-Host "non trovata" -ForegroundColor Red
    }
    Write-Host ""
}

function Cmd-Shell {
    Check-Podman
    if (-not (Container-Running)) {
        Write-Host "❌ Container non in esecuzione." -ForegroundColor Red
        exit 1
    }
    Write-Host "🐚 Shell nel container $CONTAINER_NAME..."
    podman exec -it $CONTAINER_NAME /bin/bash
    if ($LASTEXITCODE -ne 0) {
        podman exec -it $CONTAINER_NAME /bin/sh
    }
}

function Cmd-Clean {
    Check-Podman
    Write-Host ""
    Write-Host "🧹 Pulizia immagini dangling..."
    $imgs = podman images -f "dangling=true" -q 2>$null
    if ($imgs) {
        $imgs | ForEach-Object { podman rmi $_ | Out-Null }
        Write-Host "🧼 Immagini dangling rimosse." -ForegroundColor Green
    } else {
        Write-Host "   Nessuna immagine dangling."
    }

    Write-Host ""
    Write-Host "🧹 Pulizia container exited..."
    $conts = podman ps -a -f "status=exited" -q 2>$null
    if ($conts) {
        $conts | ForEach-Object { podman rm $_ | Out-Null }
        Write-Host "🧼 Container exited rimossi." -ForegroundColor Green
    } else {
        Write-Host "   Nessun container exited."
    }
}

function Cmd-Reset {
    Check-Podman
    Write-Host "⚠️  Reset completo: stop + rimozione container + rimozione immagine + clean" -ForegroundColor Yellow
    $confirm = Read-Host "Confermi? [y/N]"
    if ($confirm -notmatch "^[Yy]$") {
        Write-Host "Annullato."
        return
    }
    podman rm -f $CONTAINER_NAME 2>$null
    podman rmi -f $IMAGE_NAME 2>$null
    Cmd-Clean
    Write-Host "✅ Reset completato." -ForegroundColor Green
}

function Cmd-Help {
    Write-Host ""
    Write-Host "HP.ps1 — Utility Service manager (Windows + Podman)" -ForegroundColor White
    Write-Host ""
    Write-Host "USO" -ForegroundColor White
    Write-Host "  .\HP.ps1 <comando>"
    Write-Host ""
    Write-Host "COMANDI" -ForegroundColor White
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
    Write-Host "ESEMPI" -ForegroundColor White
    Write-Host "  .\HP.ps1 deploy    # primo avvio o aggiornamento"
    Write-Host "  .\HP.ps1 logs      # segui i log"
    Write-Host "  .\HP.ps1 status    # verifica stato e health"
    Write-Host "  .\HP.ps1 restart   # restart rapido senza rebuild"
    Write-Host ""
    Write-Host "NOTA" -ForegroundColor White
    Write-Host "  Se PowerShell blocca l'esecuzione degli script:"
    Write-Host "  Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned"
    Write-Host ""
}

# ── Entrypoint ────────────────────────────────────────────────────────────────
function Cmd-Init {
    Write-Host ""
    Write-Host "init va eseguito su Mac/Linux:" -ForegroundColor Yellow
    Write-Host "  ./handle_project.sh init" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Su Windows con WSL:" -ForegroundColor Yellow
    Write-Host "  wsl bash handle_project.sh init" -ForegroundColor Cyan
    Write-Host ""
}

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
