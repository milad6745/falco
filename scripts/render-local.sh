#!/usr/bin/env bash
set -euo pipefail
REGISTRY="${1:?Usage: render-local.sh <internal-registry-host:port>}"
CHART="${2:?Provide local chart tgz path, e.g. charts/falco-4.8.1.tgz}"
# This profile targets chart 4.8.1; image settings must be revalidated if chart changed.
helm template falco "$CHART" -n falco -f offline-values.yaml \
  --set image.registry="$REGISTRY" \
  --set driver.loader.initContainer.image.registry="$REGISTRY" \
  > rendered-local.yaml
# Ensure no unexpected public container image remains.
if grep -Eq 'image: ["'"']?(docker.io|ghcr.io|quay.io|public.ecr.aws)/' rendered-local.yaml; then
  echo 'ERROR: rendered manifest still contains PUBLIC image reference' >&2
  exit 1
fi
echo 'Created rendered-local.yaml (inspect before deployment)'
