#!/usr/bin/env bash
#
# Deploy web profile (Influence Speak Pro) on the VPS:
# pull latest code, rebuild the image, restart the container,
# wait for the app to respond on HTTP, and clean up dangling images.
#
# Usage (on the VPS, inside /srv/profile):
#   ./deploy.sh        (atau: bash deploy.sh)
#
# Aman dijalankan dari direktori manapun — script cd ke folder repo-nya sendiri.
#
set -euo pipefail

CONTAINER="profile"   # container_name di docker-compose.yml
SERVICE="profile"     # nama service di docker-compose.yml
PORT=4321             # port yang di-listen app Node
MAX_WAIT=90           # batas waktu (detik) menunggu HTTP siap

log()  { echo "==> $*"; }
fail() { echo "!! $*" >&2; exit 1; }

cd "$(dirname "$0")"

# ---- 1. pull ----
log "Pulling latest code..."
# --ff-only: gagal dengan jelas jika ada commit diverging lokal,
# daripada diam-diam membuat merge commit.
git pull --ff-only

# ---- 2. build & start ----
log "Building image and (re)starting container..."
docker compose up -d --build

# ---- 3. health probe ----
# Port $PORT tidak di-expose ke host (hanya di jaringan 'edge'),
# jadi probe dilakukan dari dalam container melalui Node HTTP client
# yang selalu tersedia di image node:22-slim.
log "Waiting for container '$CONTAINER' to serve HTTP on port $PORT..."
for i in $(seq 1 "$MAX_WAIT"); do
    state=$(docker inspect --format '{{.State.Status}}' "$CONTAINER" 2>/dev/null || echo "missing")

    case "$state" in
        running)
            if docker exec "$CONTAINER" node -e "
const http = require('http');
const req = http.get('http://localhost:${PORT}/', res => {
  process.exit(res.statusCode < 500 ? 0 : 1);
});
req.on('error', () => process.exit(1));
req.setTimeout(3000, () => { req.destroy(); process.exit(1); });
" 2>/dev/null; then
                log "HTTP OK — container is up and healthy."
                break
            fi
            ;;
        exited|dead)
            echo "!! Container stopped unexpectedly (state: $state). Recent logs:"
            docker compose logs --tail 40 "$SERVICE"
            exit 1
            ;;
        missing)
            fail "Container '$CONTAINER' tidak ditemukan setelah start."
            ;;
    esac

    if [ "$i" -eq "$MAX_WAIT" ]; then
        echo "!! Timed out after ${MAX_WAIT}s (last state: $state). Recent logs:"
        docker compose logs --tail 40 "$SERVICE"
        exit 1
    fi
    sleep 1
done

# ---- 4. prune ----
log "Pruning dangling images..."
docker image prune -f

# ---- 5. done ----
log "Done."
docker compose ps
