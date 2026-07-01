# Dropbox as a Container

Run the official Linux Dropbox client inside a single, self-contained Docker image, ready to pull and run from Docker Hub.

Unlike a compose-based setup, this image needs no build context or external files to run — it's built to work standalone with `docker run` or a minimal compose snippet. The Dropbox daemon is installed once at build time; the service account is created at container startup, so its UID/GID can be changed per-container without rebuilding the image.

## Features

* Runs the official Linux Dropbox client inside Docker
* Self-contained: no companion files needed at runtime, only the image
* Service account created at container startup, not build time
* UID/GID mapping configurable via environment variables, per container
* Dropbox daemon installed once at build time — no network dependency on container start
* No credentials generated or stored in the image
* Safe to extend: a child image's own `CMD` still runs after account setup

## Image contents

```text
.
├── Dockerfile
└── entrypoint.sh
```

## Configuration

All configuration is done via environment variables at **container runtime** — there's no `.env` file or build args required.

| Variable       | Default    | Description                              |
| -------------- | ---------- | ----------------------------------------- |
| `USERACCOUNT`  | `dropbox`  | Username created inside the container     |
| `GROUPACCOUNT` | `dropbox`  | Group name created inside the container   |
| `PUID`         | `1000`     | User ID used inside the container          |
| `PGID`         | `100`      | Group ID used inside the container         |

## Usage

Pull and run:

```bash
docker run -d \
  --name dropbox \
  -e PUID=1000 \
  -e PGID=100 \
  -v dropbox-home:/home/dropbox \
  yourname/dropbox-docker
```

Or with Docker Compose:

```yaml
services:
  dropbox:
    image: yourname/dropbox-docker
    environment:
      - USERACCOUNT=dropbox
      - GROUPACCOUNT=dropbox
      - PUID=1000
      - PGID=100
    volumes:
      - dropbox-home:/home/dropbox

volumes:
  dropbox-home:
```

Check logs:

```bash
docker logs dropbox
```

On first startup Dropbox will display an authorization URL. Open it in a browser and link your Dropbox account.

## Storage

Mount a volume at `/home/${USERACCOUNT}` to persist the Dropbox environment across container recreations, including:

* Dropbox files
* Dropbox account configuration
* Dropbox application data

## Extending this image

The entrypoint performs account setup (create user/group, prepare directories, link the Dropbox daemon), then runs whatever command it's given — defaulting to `dropboxd` via `CMD ["dropboxd"]`. A child image can supply its own `CMD` and it will still run after account setup completes, as the unprivileged user, as long as the entrypoint itself isn't overridden.

```dockerfile
FROM yourname/dropbox-docker
CMD ["some-other-command"]
```

## Notes

* No password is generated for the created account, and no credentials are baked into the image.
* Changing `PUID`/`PGID` between container runs does not require rebuilding the image.

## License

This project is licensed under the Creative Commons Attribution–NonCommercial–ShareAlike 4.0 International (CC BY-NC-SA 4.0).

https://creativecommons.org/licenses/by-nc-sa/4.0/