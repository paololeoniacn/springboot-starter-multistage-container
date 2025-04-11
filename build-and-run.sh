#!/bin/bash

IMAGE_NAME="utility-service"
CONTAINER_NAME="utility-service-container"
PORT=8080

echo "🔍 Verifica che Podman sia attivo..."

if ! podman info > /dev/null 2>&1; then
  echo "❌ Podman non è in esecuzione o non è installato correttamente."
  echo "➡️  Avvia Podman oppure verifica l'installazione."
  exit 1
else
  echo "✅ Podman è attivo!"
fi

echo -e "\n🔨 Build dell'immagine..."
podman build -t "$IMAGE_NAME" .

if podman container exists "$CONTAINER_NAME"; then
  echo -e "\n🧹 Container esistente trovato. Rimozione..."
  podman rm -f "$CONTAINER_NAME"
fi

echo -e "\n🚀 Avvio del container sulla porta $PORT..."
podman run -d --name "$CONTAINER_NAME" -p "$PORT:8080" "$IMAGE_NAME"

echo -e "\n✅ Applicazione avviata!"
echo "🌐 Vai su: http://localhost:$PORT/hello"
echo -e "\n📺 Log in tempo reale (CTRL+C per uscire)...\n"

podman logs -f "$CONTAINER_NAME"

echo -e "\n🧹 Pulizia di immagini e container dangling..."

# Rimozione immagini dangling
images_to_remove=$(podman images -f "dangling=true" -q)
if [ -n "$images_to_remove" ]; then
  echo "$images_to_remove" | xargs podman rmi >/dev/null
  echo "🧼 Immagini dangling rimosse"
else
  echo "✅ Nessuna immagine dangling da rimuovere."
fi

# Rimozione container exited
containers_to_remove=$(podman ps -a -f "status=exited" -q)
if [ -n "$containers_to_remove" ]; then
  echo "$containers_to_remove" | xargs podman rm >/dev/null
  echo "🧼 Container exited rimossi"
else
  echo "✅ Nessun container exited da rimuovere."
fi
