#!/bin/bash

IMAGE_NAME="utility-service"
CONTAINER_NAME="utility-service-container"
PORT=8080

echo "🔍 Verifica che docker sia attivo..."

if ! docker info > /dev/null 2>&1; then
  echo "❌ docker non è in esecuzione o non è installato correttamente."
  echo "➡️  Avvia docker oppure verifica l'installazione."
  exit 1
else
  echo "✅ docker è attivo!"
fi

# Ferma il container
echo -e "\n🛑 Arresto del container $CONTAINER_NAME..."
docker stop "$CONTAINER_NAME"

echo -e "\n🕒 Attesa dello stop del container $CONTAINER_NAME..."
docker wait "$CONTAINER_NAME"

echo -e "\n🧹 Pulizia di immagini e container dangling..."

# Rimozione immagini dangling
images_to_remove=$(docker images -f "dangling=true" -q)
if [ -n "$images_to_remove" ]; then
  echo "$images_to_remove" | xargs docker rmi >/dev/null
  echo "🧼 Immagini dangling rimosse"
else
  echo "✅ Nessuna immagine dangling da rimuovere."
fi

# Rimozione container exited
containers_to_remove=$(docker ps -a -f "status=exited" -q)
if [ -n "$containers_to_remove" ]; then
  echo "$containers_to_remove" | xargs docker rm >/dev/null
  echo "🧼 Container exited rimossi"
else
  echo "✅ Nessun container exited da rimuovere."
fi

echo "🔍 Docker list..."
echo ""
docker container ls
echo ""
echo ""