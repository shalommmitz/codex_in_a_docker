FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG UID=1000
ARG GID=1000

# ---- base tools ----
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git openssh-client \
    python3 python3-venv python3-pip python3-dev python3-tk \
    python3-pil python3-pil.imagetk \
    build-essential tini iputils-ping netcat-openbsd \
    pkg-config libicu-dev ripgrep dnsmasq \
    file xvfb xauth \
    bubblewrap \
 && rm -rf /var/lib/apt/lists/*

# For GUI-dependent tools in headless containers, run commands via: xvfb-run -a <cmd>

# ---- install Codex CLI (native Linux musl release tarball) ----
ARG CODEX_ARCH=

# entrypoint wrapper that starts dnsmasq (AAAA-filtering) then launches your normal CMD
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

RUN grep -qE '^\s*precedence\s+::ffff:0:0/96\s+100\s*$' /etc/gai.conf 2>/dev/null || printf '\nprecedence ::ffff:0:0/96  100\n' >> /etc/gai.conf
RUN set -eux; \
    arch="${CODEX_ARCH:-$(uname -m)}"; \
    case "${arch}" in \
        x86_64|amd64) codex_targets="x86_64-unknown-linux-musl" ;; \
        aarch64|arm64) codex_targets="aarch64-unknown-linux-musl arm64-unknown-linux-musl" ;; \
        *) echo "Unsupported Codex CLI architecture: ${arch}" >&2; exit 1 ;; \
    esac; \
    mkdir -p /tmp/codex-extract; \
    for target in ${codex_targets}; do \
        rm -rf /tmp/codex-extract/*; \
        url="https://github.com/openai/codex/releases/latest/download/codex-${target}.tar.gz"; \
        if curl -fL --retry 5 --retry-all-errors -o /tmp/codex.tgz "${url}"; then \
            tar -xzf /tmp/codex.tgz -C /tmp/codex-extract; \
            codex_bin="$(find /tmp/codex-extract -maxdepth 1 -type f -name 'codex*' | head -n 1)"; \
            if [ -n "${codex_bin}" ]; then \
                mv "${codex_bin}" /usr/local/bin/codex; \
                chmod +x /usr/local/bin/codex; \
                rm -rf /tmp/codex.tgz /tmp/codex-extract; \
                exit 0; \
            fi; \
        fi; \
    done; \
    echo "No compatible Codex CLI release archive found for architecture: ${arch}" >&2; \
    exit 1

# ---- non-root user that can write into the mounted workspace ----
RUN set -eux; \
    # --- group: create dev with GID, or rename existing group with that GID to dev ---
    if getent group "${GID}" >/dev/null; then \
        oldgrp="$(getent group "${GID}" | cut -d: -f1)"; \
        [ "$oldgrp" = "dev" ] || groupmod -n dev "$oldgrp"; \
    else \
        groupadd -g "${GID}" dev; \
    fi; \
    # --- user: create dev with UID, or rename existing user with that UID to dev ---
    if getent passwd "${UID}" >/dev/null; then \
        oldusr="$(getent passwd "${UID}" | cut -d: -f1)"; \
        [ "$oldusr" = "dev" ] || usermod -l dev "$oldusr"; \
        usermod -d /home/dev -m dev; \
        usermod -g "${GID}" -s /bin/bash dev; \
    else \
        useradd -m -u "${UID}" -g "${GID}" -s /bin/bash dev; \
    fi


USER dev
WORKDIR /workspace

#ENTRYPOINT ["/usr/bin/tini","--"]
CMD ["sleep","infinity"]
