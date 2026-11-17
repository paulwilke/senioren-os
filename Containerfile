# Senioren-OS: ein ruhiges, Mac-artiges Fedora Atomic für den MacBook Pro Retina 15" (2012)
#
# Basis: Universal Blue "silverblue-main" (Fedora Silverblue + Codecs + automatische Updates)
# Fedora-Version bewusst fest: Ein Versionssprung passiert nur, wenn wir FEDORA_MAJOR erhöhen.
ARG FEDORA_MAJOR=44

FROM scratch AS ctx
COPY build_files /build_files
COPY system_files /system_files

FROM ghcr.io/ublue-os/silverblue-main:${FEDORA_MAJOR}

ARG FEDORA_MAJOR=44

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=tmpfs,dst=/tmp \
    FEDORA_MAJOR=${FEDORA_MAJOR} /ctx/build_files/build.sh

RUN bootc container lint
