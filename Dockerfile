FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive

# --- Runtime-configurable account settings (overridable via `docker run -e`) ---
ENV USERACCOUNT=dropbox
ENV GROUPACCOUNT=dropbox
ENV PUID=1000
ENV PGID=100

# --- Install dependencies in a single layer ---
RUN apt update
RUN apt install -y --no-install-recommends \
    ca-certificates \
    curl \
    procps \
    python3 \
    python3-gpg
RUN rm -rf /var/lib/apt/lists/*

# --- Install the Dropbox daemon once, to a UID-independent shared location ---
# (dropbox.py installs to $HOME/.dropbox-dist by default, so install as root
# then relocate to /opt so it isn't tied to any particular account's home dir)
RUN curl -L https://linux.dropbox.com/packages/dropbox.py -o /opt/dropbox.py
RUN chown ${PUID}:${PGID} /opt/dropbox.py
RUN echo y | python3 /opt/dropbox.py update
RUN mv /root/.dropbox-dist /opt/dropbox-dist

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

VOLUME ["/home/${USERACCOUNT}"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["dropboxd"]