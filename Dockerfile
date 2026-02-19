FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG UID=1000
ARG GID=1000

# ---- base tools ----
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git openssh-client \
    python3 python3-venv python3-pip \
    build-essential tini iputils-ping netcat-openbsd \
 && rm -rf /var/lib/apt/lists/*

# ---- install Codex CLI (Linux x86_64 musl release tarball) ----
# Codex README documents the exact Linux x86_64 tarball name and that the archive contains a single binary
# named codex-x86_64-unknown-linux-musl that you typically rename to `codex`. :contentReference[oaicite:1]{index=1}
ARG CODEX_TGZ=codex-x86_64-unknown-linux-musl.tar.gz
ARG CODEX_BIN=codex-x86_64-unknown-linux-musl

RUN curl -fL --retry 5 --retry-all-errors -o /tmp/codex.tgz \
      "https://github.com/openai/codex/releases/latest/download/${CODEX_TGZ}" \
 && tar -xzf /tmp/codex.tgz -C /usr/local/bin \
 && mv "/usr/local/bin/${CODEX_BIN}" /usr/local/bin/codex \
 && chmod +x /usr/local/bin/codex \
 && rm -f /tmp/codex.tgz

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

ENTRYPOINT ["/usr/bin/tini","--"]
CMD ["sleep","infinity"]
