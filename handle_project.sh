#!/bin/bash
# =============================================================================
# handle_project.sh — Utility Service project manager (Mac/Linux)
# =============================================================================
# Uso: ./handle_project.sh <comando> [opzioni]
#
# Comandi:
#   build       Build dell'immagine Docker/Podman
#   deploy      Build + avvio container (o solo avvio se immagine esiste)
#   start       Avvia il container (senza rebuild)
#   stop        Ferma il container
#   restart     Ferma e riavvia il container
#   logs        Segue i log in tempo reale
#   status      Stato container + health check
#   shell       Apre una shell bash nel container in esecuzione
#   clean       Rimuove immagini dangling e container exited
#   reset       Stop + rimozione immagine + clean completo
#   help        Mostra questo messaggio
# =============================================================================

set -euo pipefail

# ── Configurazione ──────────────────────────────────────────────────────────
IMAGE_NAME="utility-service"
CONTAINER_NAME="utility-service-container"
PORT=8080
HEALTH_URL="http://localhost:${PORT}/actuator/health"
APP_URL="http://localhost:${PORT}"

# ── Colori ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Rilevamento container tool ───────────────────────────────────────────────
detect_tool() {
    if command -v podman &> /dev/null && podman info &> /dev/null 2>&1; then
        echo "podman"
    elif command -v docker &> /dev/null && docker info &> /dev/null 2>&1; then
        echo "docker"
    else
        echo ""
    fi
}

TOOL=$(detect_tool)

check_tool() {
    if [ -z "$TOOL" ]; then
        echo -e "${RED}❌ Né podman né docker trovati o attivi.${RESET}"
        echo "   Installa Podman Desktop (https://podman-desktop.io) o Docker Desktop."
        exit 1
    fi
    echo -e "${CYAN}🔧 Container tool: ${BOLD}${TOOL}${RESET}"
}

# ── Helpers ──────────────────────────────────────────────────────────────────
container_exists() {
    $TOOL ps -a --format "{{.Names}}" 2>/dev/null | grep -q "^${CONTAINER_NAME}$"
}

container_running() {
    $TOOL ps --format "{{.Names}}" 2>/dev/null | grep -q "^${CONTAINER_NAME}$"
}

image_exists() {
    $TOOL image inspect "$IMAGE_NAME" &> /dev/null 2>&1
}

wait_healthy() {
    echo -e "\n⏳ Attendo avvio applicazione..."
    local max=30
    local i=0
    while [ $i -lt $max ]; do
        if curl -sf "$HEALTH_URL" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Applicazione UP!${RESET}"
            return 0
        fi
        sleep 2
        i=$((i + 1))
        echo -n "."
    done
    echo -e "\n${YELLOW}⚠️  Health check timeout (${max}×2s). Container potrebbe ancora avviarsi.${RESET}"
    return 1
}

print_urls() {
    echo -e "\n${BOLD}📡 Endpoints:${RESET}"
    echo -e "   Hello World : ${CYAN}${APP_URL}/hello${RESET}"
    echo -e "   Swagger UI  : ${CYAN}${APP_URL}/swagger-ui.html${RESET}"
    echo -e "   Health      : ${CYAN}${HEALTH_URL}${RESET}"
    echo -e "   Actuator    : ${CYAN}${APP_URL}/actuator${RESET}"
}

# ── Comandi ──────────────────────────────────────────────────────────────────
cmd_build() {
    check_tool
    echo -e "\n${BOLD}🔨 Build immagine: ${IMAGE_NAME}${RESET}"
    $TOOL build -t "$IMAGE_NAME" .
    echo -e "\n${GREEN}✅ Build completata.${RESET}"
}

cmd_start() {
    check_tool
    if container_running; then
        echo -e "${YELLOW}⚠️  Container già in esecuzione.${RESET}"
        print_urls
        return 0
    fi
    if container_exists; then
        echo -e "\n🔄 Avvio container esistente..."
        $TOOL start "$CONTAINER_NAME"
    else
        if ! image_exists; then
            echo -e "${YELLOW}⚠️  Immagine non trovata. Eseguo build prima...${RESET}"
            cmd_build
        fi
        echo -e "\n🚀 Avvio container sulla porta ${PORT}..."
        $TOOL run -d --name "$CONTAINER_NAME" -p "${PORT}:8080" "$IMAGE_NAME"
    fi
    wait_healthy
    print_urls
}

cmd_deploy() {
    check_tool
    cmd_build
    if container_exists; then
        echo -e "\n🧹 Rimozione container precedente..."
        $TOOL rm -f "$CONTAINER_NAME"
    fi
    echo -e "\n🚀 Avvio container sulla porta ${PORT}..."
    $TOOL run -d --name "$CONTAINER_NAME" -p "${PORT}:8080" "$IMAGE_NAME"
    wait_healthy
    print_urls
}

cmd_stop() {
    check_tool
    if ! container_running; then
        echo -e "${YELLOW}⚠️  Nessun container in esecuzione.${RESET}"
        return 0
    fi
    echo -e "\n🛑 Stop container ${CONTAINER_NAME}..."
    $TOOL stop "$CONTAINER_NAME"
    echo -e "${GREEN}✅ Container fermato.${RESET}"
}

cmd_restart() {
    cmd_stop || true
    cmd_start
}

cmd_logs() {
    check_tool
    if ! container_running; then
        echo -e "${RED}❌ Container non in esecuzione.${RESET}"
        exit 1
    fi
    echo -e "📺 Log in tempo reale — ${BOLD}CTRL+C per uscire${RESET}\n"
    $TOOL logs -f "$CONTAINER_NAME"
}

cmd_status() {
    check_tool
    echo -e "\n${BOLD}📊 Status: ${IMAGE_NAME}${RESET}"
    echo -e "─────────────────────────────────────"

    if container_running; then
        echo -e "Container : ${GREEN}● running${RESET}"
        local uptime
        uptime=$($TOOL inspect "$CONTAINER_NAME" --format '{{.State.StartedAt}}' 2>/dev/null || echo "n/a")
        echo -e "Avviato   : ${uptime}"

        echo -n "Health    : "
        if curl -sf "$HEALTH_URL" > /dev/null 2>&1; then
            local health
            health=$(curl -s "$HEALTH_URL" 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('status','?'))" 2>/dev/null || echo "UP")
            echo -e "${GREEN}${health}${RESET}"
        else
            echo -e "${YELLOW}unreachable${RESET}"
        fi
        print_urls
    elif container_exists; then
        echo -e "Container : ${YELLOW}● stopped${RESET}"
    else
        echo -e "Container : ${RED}● non esiste${RESET}"
    fi

    echo ""
    if image_exists; then
        echo -n "Immagine  : "
        $TOOL image inspect "$IMAGE_NAME" --format '{{.Id}} ({{.Size}} bytes)' 2>/dev/null || echo "$IMAGE_NAME"
    else
        echo -e "Immagine  : ${RED}non trovata${RESET}"
    fi
    echo ""
}

cmd_shell() {
    check_tool
    if ! container_running; then
        echo -e "${RED}❌ Container non in esecuzione.${RESET}"
        exit 1
    fi
    echo -e "🐚 Shell nel container ${CONTAINER_NAME}..."
    $TOOL exec -it "$CONTAINER_NAME" /bin/bash || $TOOL exec -it "$CONTAINER_NAME" /bin/sh
}

cmd_clean() {
    check_tool
    echo -e "\n🧹 Pulizia immagini dangling..."
    local imgs
    imgs=$($TOOL images -f "dangling=true" -q 2>/dev/null)
    if [ -n "$imgs" ]; then
        echo "$imgs" | xargs $TOOL rmi
        echo -e "${GREEN}🧼 Immagini dangling rimosse.${RESET}"
    else
        echo "   Nessuna immagine dangling."
    fi

    echo -e "\n🧹 Pulizia container exited..."
    local conts
    conts=$($TOOL ps -a -f "status=exited" -q 2>/dev/null)
    if [ -n "$conts" ]; then
        echo "$conts" | xargs $TOOL rm
        echo -e "${GREEN}🧼 Container exited rimossi.${RESET}"
    else
        echo "   Nessun container exited."
    fi
}

cmd_reset() {
    check_tool
    echo -e "${YELLOW}⚠️  Reset completo: stop + rimozione container + rimozione immagine + clean${RESET}"
    read -rp "Confermi? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Annullato."; exit 0; }

    $TOOL rm -f "$CONTAINER_NAME" 2>/dev/null || true
    $TOOL rmi -f "$IMAGE_NAME" 2>/dev/null || true
    cmd_clean
    echo -e "${GREEN}✅ Reset completato.${RESET}"
}

cmd_help() {
    echo -e ""
    echo -e "${BOLD}handle_project.sh${RESET} — Utility Service manager"
    echo -e ""
    echo -e "${BOLD}USO${RESET}"
    echo -e "  ./handle_project.sh <comando>"
    echo -e ""
    echo -e "${BOLD}COMANDI${RESET}"
    echo -e "  ${CYAN}build${RESET}     Build immagine (multistage Dockerfile)"
    echo -e "  ${CYAN}deploy${RESET}    Build + avvio container (full redeploy)"
    echo -e "  ${CYAN}start${RESET}     Avvia container (senza rebuild)"
    echo -e "  ${CYAN}stop${RESET}      Ferma il container"
    echo -e "  ${CYAN}restart${RESET}   Ferma e riavvia"
    echo -e "  ${CYAN}logs${RESET}      Log in tempo reale (CTRL+C per uscire)"
    echo -e "  ${CYAN}status${RESET}    Stato container + health check"
    echo -e "  ${CYAN}shell${RESET}     Shell bash nel container"
    echo -e "  ${CYAN}clean${RESET}     Rimuovi immagini dangling + container exited"
    echo -e "  ${CYAN}reset${RESET}     Stop + rimozione immagine + clean totale"
    echo -e "  ${CYAN}help${RESET}      Questo messaggio"
    echo -e ""
    echo -e "${BOLD}ESEMPI${RESET}"
    echo -e "  ./handle_project.sh deploy    # primo avvio o aggiornamento"
    echo -e "  ./handle_project.sh logs      # segui i log"
    echo -e "  ./handle_project.sh status    # verifica stato e health"
    echo -e "  ./handle_project.sh restart   # restart rapido senza rebuild"
    echo -e ""
}

# ── Entrypoint ───────────────────────────────────────────────────────────────
COMMAND="${1:-help}"

case "$COMMAND" in
    build)   cmd_build   ;;
    deploy)  cmd_deploy  ;;
    start)   cmd_start   ;;
    stop)    cmd_stop    ;;
    restart) cmd_restart ;;
    logs)    cmd_logs    ;;
    status)  cmd_status  ;;
    shell)   cmd_shell   ;;
    clean)   cmd_clean   ;;
    reset)   cmd_reset   ;;
    help|--help|-h) cmd_help ;;
    *)
        echo -e "${RED}❌ Comando sconosciuto: ${COMMAND}${RESET}"
        cmd_help
        exit 1
        ;;
esac
