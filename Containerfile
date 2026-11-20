# Senioren-OS: a calm, Mac-like Fedora Atomic for the MacBook Pro Retina 15" (2012)
#
# Base: Universal Blue "silverblue-main" (Fedora Silverblue + codecs + automatic updates)
# Fedora version pinned on purpose: a major upgrade only happens when we raise FEDORA_MAJOR.
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
