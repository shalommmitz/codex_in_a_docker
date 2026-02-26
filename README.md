# How-to: Install and run Codex inside a docker instance

This repository contains procedure and scripts.

Motivation: make sure codex does not access anything on the machine beside what it should access.

## Prerequisites:

- Ubuntu (or variant) 22.04
- On windows, it is recommended to either install WSL2 (gives you a full Ubuntu environment) OR work on virtual machine

## Dependencies Installation

- install docker: `sudo apt install -y docker.io`
- Install the Python package "textual": `pip install textual`

## Allow regular user to run `docker` commands without `sudo`

- Add your user to the 'docker' group 

  DANGER: This will give you permanent root rights

  `sudo usermod -aG docker user`
  
  (replace "user" with your user name)

- Apply the new group membership

  - Option A: log-out and log-in again
  - Option B: Start a new shell with the new group active:
  
    `newgrp docker`

## Build the docker: 

   `. build_docker`

## Setup authentication

Perform ONE of the two options below:

### Setup API key

Run `. setup_codex_api_key` and enter the API key

NOTE: if you use this to add the API key, you do NOT need to run the next section.

### Setup authentication (no API key)

NOTE: do not run the below if you added the API key

- This procedure requires the "pro" plan (20$/mo). No API key is used.

- Run the docker instance: . run_docker_first_time

- Connect to the docker: . connect_first_time

- A long URL will be displayed. Copy this URL

- In the host, open a browser and past the URL 
  
  E.g., `firefox <the URL copied/paste from the output of the "docker login">`

  Note: if the host is a VM, you might need to create an SSH tunnel to port 1455

- when done, run "stop_docker" to stop the running "first time" docker


## Usage:

### Switching project:

- Create at least one sub-folders that will contain the projects (can be empty for now)
- Run `./set_current_project` to select which of the sub-folders will be called 'code' and seen by the docker
- Run `. stop_docker;. run_docker`

### Interact with Codex:

- Run `. connect`
- Interact with Codex
- When done: `/quit`
