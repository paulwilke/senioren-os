#!/usr/bin/env bash
# Senioren-OS lokal bauen (auf dem Mac mit Podman).
#   ./build.sh image   -> Container-Image bauen (x86_64, läuft auf Apple Silicon per Emulation)
#   ./build.sh iso     -> Installations-ISO nach ./output erzeugen
#   ./build.sh push    -> Image nach ghcr.io hochladen (Quelle für den Nutzers Updates)
set -euo pipefail
cd "$(dirname "$0")"

IMAGE=localhost/senioren-os:latest
REMOTE=ghcr.io/paulwilke/senioren-os:latest
# ISO und Image müssen im "rootful" Podman-Speicher liegen
PODMAN=(podman --connection podman-machine-default-root)

case "${1:-}" in
  image)
    "${PODMAN[@]}" build --platform linux/amd64 --pull=newer -t "$IMAGE" .
    ;;
  iso)
    mkdir -p output
    "${PODMAN[@]}" run --rm -it --privileged --platform linux/amd64 \
      --security-opt label=type:unconfined_t \
      -v "$PWD/iso/config.toml:/config.toml:ro" \
      -v "$PWD/output:/output" \
      -v /var/lib/containers/storage:/var/lib/containers/storage \
      quay.io/centos-bootc/bootc-image-builder:latest \
      --type anaconda-iso --rootfs btrfs --use-librepo=True \
      --target-arch amd64 \
      "$IMAGE"
    ls -lh output/bootiso/
    ;;
  push)
    "${PODMAN[@]}" tag "$IMAGE" "$REMOTE"
    "${PODMAN[@]}" push "$REMOTE"
    ;;
  *)
    sed -n '2,6p' "$0"; exit 1 ;;
esac
