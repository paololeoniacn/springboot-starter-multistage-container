#!/bin/bash

IMAGE_NAME="utility-service"
CONTAINER_NAME="utility-service-container"
PORT=8080

# Rilevamento container tool: podman (preferito) o docker
if command -v podman &> /dev/null; then
    TOOL="podman"
elif command -v docker &> /dev/null; then
    TOOL="docker"
else
    echo "❌ Errore: né podman né docker trovati. Installa uno dei due e riprova."
    exit 1
fi

echo "🔧 Container tool: $TOOL"

echo -e "\n🔍 Verifica che $TOOL sia attivo..."
if ! $TOOL info > /dev/null 2>&1; then
    echo "❌ $TOOL non è in esecuzione o non è installato correttamente."
    echo "➡️  Avvia $TOOL oppure verifica l'installazione."
    exit 1
fi
echo "✅ $TOOL è attivo!"

echo -e "\n🔨 Build dell'immagine (multistage)..."
$TOOL build -t "$IMAGE_NAME" .

if [ $? -ne 0 ]; then
    echo "❌ Errore durante la build dell'immagine."
    exit 1
fi

if $TOOL ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "\n🧹 Container esistente trovato. Rimozione..."
    $TOOL rm -f "$CONTAINER_NAME"
fi

echo -e "\n🚀 Avvio del container sulla porta $PORT..."
$TOOL run -d --name "$CONTAINER_NAME" -p "$PORT:8080" "$IMAGE_NAME"

echo -e "\n✅ Applicazione avviata!"
echo "🌐 Vai su: http://localhost:$PORT/hello"
echo "📋 Swagger:  http://localhost:$PORT/swagger-ui.html"
echo "❤️  Health:  http://localhost:$PORT/actuator/health"
echo -e "\n📺 Log in tempo reale (CTRL+C per uscire)...\n"

$TOOL logs -f "$CONTAINER_NAME"

# Ferma il container
echo -e "\n🛑 Arresto del container $CONTAINER_NAME..."
$TOOL stop "$CONTAINER_NAME"

echo -e "\n🕒 Attesa dello stop del container $CONTAINER_NAME..."
$TOOL wait "$CONTAINER_NAME"

echo -e "\n🧹 Pulizia di immagini e container dangling..."

images_to_remove=$($TOOL images -f "dangling=true" -q)
if [ -n "$images_to_remove" ]; then
    echo "$images_to_remove" | xargs $TOOL rmi >/dev/null
    echo "🧼 Immagini dangling rimosse"
else
    echo "✅ Nessuna immagine dangling da rimuovere."
fi

containers_to_remove=$($TOOL ps -a -f "status=exited" -q)
if [ -n "$containers_to_remove" ]; then
    echo "$containers_to_remove" | xargs $TOOL rm >/dev/null
    echo "🧼 Container exited rimossi"
else
    echo "✅ Nessun container exited da rimuovere."
fi
