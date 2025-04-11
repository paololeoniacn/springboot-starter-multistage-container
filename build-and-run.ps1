# Nome immagine e container
$IMAGE_NAME = "utility-service"
$CONTAINER_NAME = "utility-service-container"
$PORT = 8080

# --- STEP 0: Controlla se Podman è disponibile e in esecuzione ---
Write-Host "🔍 Verifica che Podman sia attivo..."

try {
    podman info > $null 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Podman non risponde"
    } else {
        Write-Host "`n✅ Podman presente ed avviato!"
    }
} catch {
    Write-Host "❌ Podman non è in esecuzione o non è installato correttamente."
    Write-Host "➡️  Avvia il servizio Podman Desktop oppure controlla l'installazione."
    exit 1
}

# --- STEP 0: Pulizia immagini/container "dangling" ---
Write-Host "`n🧹 Pulizia di immagini e container dangling..."

# Rimuove immagini dangling
$imagesToRemove = podman images -f "dangling=true" -q
if ($imagesToRemove) {
    podman rmi $imagesToRemove | Out-Null
    Write-Host "🧼 Immagini dangling rimosse: $($imagesToRemove.Count)"
} else {
    Write-Host "✅ Nessuna immagine dangling da rimuovere."
}

# Rimuove container exited/dangling
$containersToRemove = podman ps -a -f "status=exited" -q
if ($containersToRemove) {
    podman rm $containersToRemove | Out-Null
    Write-Host "🧼 Container exited rimossi: $($containersToRemove.Count)"
} else {
    Write-Host "✅ Nessun container exited da rimuovere."
}

# --- STEP 1: Build dell'immagine ---
Write-Host "`n🔨 Build dell'immagine..."
podman build -t $IMAGE_NAME .

# --- STEP 2: Rimuove eventuale container precedente ---
if (podman container exists $CONTAINER_NAME) {
    Write-Host "`n🧹 Container esistente trovato. Rimozione..."
    podman rm -f $CONTAINER_NAME
}

# --- STEP 3: Avvio del container con porta esposta ---
Write-Host "`n🚀 Avvio del container sulla porta $PORT..."
podman run -d --name "$CONTAINER_NAME" -p "8080:8080" "$IMAGE_NAME"

# --- STEP 4: Info finale ---
Write-Host "`n✅ Applicazione avviata!"
Write-Host "🌐 Vai su: http://localhost:8080/hello"
Write-Host "`n📺 Mostro i log in tempo reale (CTRL+C per uscire)...`n"

# --- STEP 5: Visualizza log in tempo reale ---
podman logs -f "$CONTAINER_NAME"


