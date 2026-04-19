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

# ---- install Codex CLI (Linux x86_64 musl release tarball) ----
# The release archive contains a single binary named below; install it as `codex`.
ARG CODEX_TGZ=codex-x86_64-unknown-linux-musl.tar.gz
ARG CODEX_BIN=codex-x86_64-unknown-linux-musl

# entrypoint wrapper that starts dnsmasq (AAAA-filtering) then launches your normal CMD
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

RUN grep -qE '^\s*precedence\s+::ffff:0:0/96\s+100\s*$' /etc/gai.conf 2>/dev/null || printf '\nprecedence ::ffff:0:0/96  100\n' >> /etc/gai.conf
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

#ENTRYPOINT ["/usr/bin/tini","--"]
CMD ["sleep","infinity"]
