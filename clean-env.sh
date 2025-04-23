#!/bin/bash

IMAGE_NAME="utility-service"
CONTAINER_NAME="utility-service-container"
PORT=8080

echo "🔍 Verifica che podman sia attivo..."

if ! podman info > /dev/null 2>&1; then
  echo "❌ podman non è in esecuzione o non è installato correttamente."
  echo "➡️  Avvia podman oppure verifica l'installazione."
  exit 1
else
  echo "✅ podman è attivo!"
fi

# Ferma il container
echo -e "\n🛑 Arresto del container $CONTAINER_NAME..."
podman stop "$CONTAINER_NAME"

echo -e "\n🕒 Attesa dello stop del container $CONTAINER_NAME..."
podman wait "$CONTAINER_NAME"

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

echo "🔍 podman list..."
echo ""
podman container ls
echo ""
echo ""