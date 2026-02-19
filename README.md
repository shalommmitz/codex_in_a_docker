# Procedure to run codex inside A docker instance

Motivation: make sure codex does not access anything on the machine beside what it should access.

## Prerequisites:

- Ubuntu (or variant) 22.04

## Installation:

- install docker: sudo apt install -y docker.io
- Add your user to the 'docker' group 

DANGER: This will give you permanent root rights

- Build the docker: . build_docker
- Install pip package textual: `pip install textual`
- Perform one of the two options below:

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

- Run `./set_current_project` to select which of the sub-folders will be called 'code' and seen by the docker
- Run `. connect`
- When done: `/quit`
