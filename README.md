# Procedure to run codex inside A docker instance

Motivation: make sure codex does not access anything on the machine beside what it should access.

## Prerequisites:

- Ubuntu (or variant) 22.04

## Installation:

- install docker: sudo apt install -y docker.io
- Add your user to the 'docker' group DANGER: give you permanent root 
- Build: . build_docker

## First time authentication by authenticating 

- This requires the "pro" plan (20$/mo). No API key is used

- Run the docker instance: . run_docker_first_time

- Connect to the docker: . connect_first_time

- A long URL will be displayed. Copy this URL

- In the host, open a browser and past the URL 
  
  E.g., `firefox <the URL copied/paste from the output of the "docker login">`
