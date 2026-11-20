#!/usr/bin/env bash
# Build Senioren-OS locally (on the Mac with Podman).
#   ./build.sh image   -> build the container image (x86_64, runs on Apple Silicon via emulation)
#   ./build.sh iso     -> create the installation ISO in ./output
#   ./build.sh push    -> push the image to ghcr.io (the source of the machines' updates)
set -euo pipefail
cd "$(dirname "$0")"

IMAGE=localhost/senioren-os:latest
REMOTE=ghcr.io/paulwilke/senioren-os:latest
# ISO and image must live in the "rootful" Podman storage
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
