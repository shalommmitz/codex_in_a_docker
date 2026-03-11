# Run Codex in a Docker Sandbox

This repository provides a few scripts for running the Codex CLI inside a locked-down Docker container. The goal is to keep Codex focused on a single mounted workspace instead of your full host machine.
This ensures Codex (and ChatGPT, to which it communicates) can not see, or act, on anything not intended on the host.
cccccThe container only persists data in two host locations:

- `./code`, mounted as `/workspace/code`
- `~/.codex-docker`, mounted as `/home/dev/.codex`

All scripts can be run from any working directory; they resolve paths relative to this repository.

## Prerequisites

- Ubuntu 22.04+ or WSL2 with a Linux Docker daemon
- Docker Engine installed and usable from your normal user account
- Internet access to build the image and to let Codex reach its upstream services

No extra Python packages are required.

## Install Docker

Install Docker on Ubuntu or WSL2:

```bash
sudo apt update
sudo apt install -y docker.io
```

To run Docker without `sudo`, add your user to the `docker` group:

```bash
sudo usermod -aG docker "$USER"
```

This effectively grants root-equivalent Docker access. Apply the new group membership by logging out and back in, or by starting a new shell:

```bash
newgrp docker
```

## Build the Image

Build the local image:

```bash
./build_docker
```

This creates the image `codex-py:24.04`. The script uses a minimal `tmp/` build context so large sibling projects are not sent to `docker build`.

## Configure Authentication

Use exactly one of the following methods.

### Option 1: API Key

Store an API key in `~/.codex-docker/auth.json`:

```bash
./setup_codex_api_key
```

The script creates the file with restrictive permissions. If you use this option, you do not need the browser login flow below.

### Option 2: Browser Login

Use this only if you are not configuring an API key.

1. Start the temporary login container:

   ```bash
   ./run_docker_first_time
   ```

2. Launch the login flow inside the container:

   ```bash
   ./connect_first_time
   ```

3. Copy the URL printed by `codex login`, then open it in a browser on the host.

4. After the browser flow completes, remove the temporary container:

   ```bash
   ./stop_docker
   ```

`run_docker_first_time` uses host networking so the local login callback can complete. That mode is only for the one-time browser login flow.

If your host is a remote VM, you may need an SSH tunnel for port `1455`.

## Start and Use Codex

Start the normal container:

```bash
./run_docker
```

Then connect to Codex:

```bash
./connect
```

Exit the Codex session with `/quit`.

To stop and remove the container:

```bash
./stop_docker
```

`./stop_docker` removes the container, but it does not delete `./code`, `~/.codex-docker`, or the Docker image.

## Choose Which Project Is Mounted

By default, `./run_docker` creates `./code` if it does not exist and mounts that directory.

If you want `./code` to point at one of this repository's sibling project folders instead:

1. Create the project folder inside this repository.
2. Run:

   ```bash
   ./set_current_project
   ```

3. Select the folder to link as `./code`.
4. Restart the container if it is already running:

   ```bash
   ./stop_docker
   ./run_docker
   ```

`./set_current_project` replaces `./code` with a symlink. It will refuse to delete a non-empty real `./code` directory.

## Security Model

The normal container is intentionally constrained:

- Runs as a non-root user whose UID and GID match the host user
- Drops all Linux capabilities
- Enables `no-new-privileges`
- Uses a read-only root filesystem
- Uses `tmpfs` mounts for `/tmp` and `/run`

This setup limits what Codex can modify on the host while still allowing it to work inside the mounted project directory.

## Troubleshooting

- If `./run_docker` says the image is missing, run `./build_docker`.
- If `./run_docker` says the `codex` container already exists, run `./stop_docker`.
- If `./connect` fails, the container is probably not running. Start it with `./run_docker`.
- If browser login does not complete, confirm that the temporary login container is running and that port `1455` is reachable from your browser host.
