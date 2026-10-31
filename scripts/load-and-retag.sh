#!/usr/bin/env bash
# Requires Docker on a registry-connected machine. It loads the exported images
# and pushes them to an INTERNAL registry using source registry/repository/tag.
set -euo pipefail
REGISTRY="${1:?Usage: load-and-retag.sh <internal-registry-host:port>}"
BUNDLE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
docker load -i "$BUNDLE_DIR/images/falco-images.tar"
while IFS= read -r IMAGE; do
  [ -n "$IMAGE" ] || continue
  # Images expected from Docker Hub; explicitly retain path in internal registry.
  NAME="${IMAGE#docker.io/}"
  if [[ "$NAME" != */* ]]; then NAME="library/$NAME"; fi
  DEST="$REGISTRY/$NAME"
  echo "Tag & push: $IMAGE -> $DEST"
  docker tag "$IMAGE" "$DEST"
  docker push "$DEST"
done < "$BUNDLE_DIR/images.txt"
