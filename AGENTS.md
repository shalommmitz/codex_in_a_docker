# AGENTS.md

## Purpose

This repository is an operational wrapper around the Codex CLI. It is not an app/library repository; it is an operator toolchain made of:

- a Docker image definition
- host-side scripts to build and run that image
- helper scripts for authentication and project-folder selection

Small script changes can directly affect local developer machines. Treat behavior changes as operational changes: make them explicit, minimal, and documented.

## Repository Scope

- `README.md`: operator-facing source of truth. Keep it aligned with actual script behavior.
- `Dockerfile`: builds image `codex-py:24.04` and creates non-root user `dev` with host UID/GID.
- `.dockerignore`: limits build context contents copied by `build_docker`.
- `build_docker`: recreates `tmp_docker_build_folder/`, copies build inputs, runs `docker build`.
- `build_docker_and_update_codex`: rebuilds image with `--pull --no-cache` using `tmp/` context to refresh Codex installation.
- `run_docker`: starts the normal long-lived locked-down container `codex`.
- `run_docker_first_time`: starts temporary host-networked container for browser login flow.
- `connect`: runs `codex` inside the running container.
- `connect_first_time`: runs `codex login` inside the running container.
- `stop_docker`: stops and removes container `codex` (if present).
- `set_current_project`: selects a sibling folder, rewires `./code` symlink, then runs `stop/build/run`.
- `setup_codex_api_key`: writes `~/.codex-docker/auth.json` with restrictive permissions.
- `update_codex`: operational shortcut that runs `stop_docker`, `build_docker_and_update_codex`, then `run_docker`.
- `docker-entrypoint.sh`: DNS helper currently copied into build context but not wired by `Dockerfile`.
- `tmp_docker_build_folder/`: disposable build context created by `build_docker`.

## Current Behavior Contract

Recent commits changed runtime flow and preconditions. Preserve these unless the user explicitly asks for behavior changes.

- `run_docker` precondition: image `codex-py:24.04` exists.
- `run_docker` precondition: no `codex` container already exists.
- `run_docker` precondition: `./code` is a symlink.
- `run_docker` precondition: resolved symlink target exists and stays within repo root.
- `run_docker` precondition: `~/.codex-docker` already exists.
- `set_current_project` now does more than relinking `./code`: it runs `./stop_docker`, `./build_docker`, and `./run_docker`.
- `run_docker_first_time` is still the only path that intentionally uses `--network host`.
- `stop_docker` remains idempotent and safe when container does not exist.
- `connect`/`connect_first_time` expect container name `codex` and run Codex from `/workspace/code`.
- `update_codex` performs an in-place refresh cycle by running `./stop_docker`, `./build_docker_and_update_codex` (`--pull --no-cache`), then `./run_docker` (therefore inherits all `run_docker` preconditions).

If you change image tags, container names, mount points, auth paths, or symlink expectations, audit every script and `README.md` in the same change.

## Canonical Workflows

### API key path

1. `./build_docker`
2. `./setup_codex_api_key`
3. `./set_current_project` (this now also rebuilds/restarts container)
4. `./connect`

### Browser login path

1. `./build_docker`
2. `./run_docker_first_time`
3. `./connect_first_time`
4. Complete browser flow
5. `./stop_docker`
6. `./set_current_project`
7. `./connect`

Keep script behavior and README sequence coherent. Any mismatch is a real defect.

### Codex refresh path

1. `./update_codex`
2. If startup fails, satisfy `run_docker` preconditions first (`./set_current_project`, auth setup, image/build prerequisites).

## Security And Privacy Guardrails

- Preserve hardening defaults in container launch scripts unless explicitly asked to relax them.
- Required hardening flag: `--cap-drop ALL`.
- Required hardening flag: `--security-opt no-new-privileges:true`.
- Required hardening flag: `--read-only`.
- Required hardening setting: `--tmpfs` mounts for writable temporary paths.
- Do not add privileged mode, extra host mounts, or host networking to normal `run_docker`.
- Keep host networking restricted to one-time login flow (`run_docker_first_time`).
- Never print secrets or loosen file permissions under `~/.codex-docker`.
- Keep `setup_codex_api_key` behavior aligned with `umask 077`, directory `700`, file `600`.
- Do not delete a non-empty real `./code` directory to force symlink recreation.

## Change Guidelines

- Prefer strict Bash in shell scripts: `#!/usr/bin/env bash` and `set -euo pipefail`.
- Keep scripts explicit and audit-friendly; avoid unnecessary abstraction.
- Prefer paths relative to script location for path robustness.
- Keep dependencies minimal; `set_current_project` should stay standard-library only.
- If new repository-internal directories are added, evaluate `set_current_project` exclusion list.
- If you change user-facing behavior, update `README.md` in the same change.
- If you touch auth, preserve overwrite-confirmation behavior and permission model.

## Commit-Aware Review Expectations

Before editing scripts/docs, scan recent history (at least `git log --oneline -n 10`) and check diffs for touched files. This repository has behavior shifts concentrated in small commits, so commit intent matters.

Pay special attention to commits that changed:

- startup preconditions (`run_docker`)
- project switching semantics (`set_current_project`)
- authentication setup/permissions (`setup_codex_api_key`, first-time flow)
- networking behavior (`run_docker_first_time`, any DNS-related entrypoint changes)
- image refresh/update flow (`update_codex`, `build_docker_and_update_codex`)

## Validation Checklist

For documentation or script changes, run:

- `bash -n build_docker build_docker_and_update_codex run_docker run_docker_first_time connect connect_first_time stop_docker setup_codex_api_key update_codex`
- `python3 -m py_compile set_current_project`
- reread `README.md` once after edits to verify filenames, command sequence, and behavior claims

If you changed startup/project-selection behavior, additionally check:

- `run_docker` precondition messages still match real checks
- `set_current_project` post-selection actions still match README instructions
- login flow remains isolated to `run_docker_first_time`

Do not run destructive container commands against the user's active environment unless the task requires it.

## Common Pitfalls

- `build_docker` uses `tmp_docker_build_folder/`, not `tmp/`.
- `build_docker_and_update_codex` uses `tmp/` and `--pull --no-cache`; keep this divergence intentional and documented.
- `.dockerignore` controls what enters the temporary build context; keep it consistent with copied files.
- `build_docker` currently assumes it is launched from repo root; if this is changed, update script path handling and README together.
- `run_docker` and `run_docker_first_time` are mutually exclusive because both use container name `codex`.
- `run_docker` now requires `./code` to be a symlink; README and scripts must stay aligned on this.
- `set_current_project` now performs container lifecycle actions; document this side effect whenever changed.
