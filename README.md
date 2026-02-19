# Procedure to run codex inside A docker instance

Motivation: make sure codex does not access anything on the machine beside what it should access.

## Prerequisites:

- Ubuntu (or variant) 22.04

Installation:

- install docker: sudo apt install -y docker.io
- Add your user to the 'docker' group DANGER: give you permanent root 
- Build: . build_docker

## First time authentication using "pro" (the 20$/mo plan, w/o API key)

- Run the docker instance: . run_docker

   host network
- Connect to the docker: . connect
- (now insider the docker) login to codex: docker exec -it codex bash
- (in a different terminal on the host): authenticate:
   Firefox <the URL copied/paste from the output of the "docker login">
