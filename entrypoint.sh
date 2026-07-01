#!/bin/sh
set -e

USERACCOUNT="${USERACCOUNT:-dropbox}"
GROUPACCOUNT="${GROUPACCOUNT:-dropbox}"
PUID="${PUID:-1000}"
PGID="${PGID:-100}"

# --- Create group if it doesn't exist ---
if ! getent group "${PGID}" > /dev/null 2>&1; then
    groupadd -g "${PGID}" "${GROUPACCOUNT}"
fi

# --- Create user if it doesn't exist ---
if ! getent passwd "${PUID}" > /dev/null 2>&1; then
    useradd -m -u "${PUID}" -g "${PGID}" -s /bin/sh "${USERACCOUNT}"
fi

HOME_DIR="$(getent passwd "${PUID}" | cut -d: -f6)"

mkdir -p "${HOME_DIR}/.dropbox"

# Link the daemon (installed once at build time under /opt) into the user's home
if [ ! -e "${HOME_DIR}/.dropbox-dist" ]; then
    ln -s /opt/dropbox-dist "${HOME_DIR}/.dropbox-dist"
fi

chown -R "${PUID}:${PGID}" "${HOME_DIR}"

# If the first argument is "dropboxd", run the daemon as the unprivileged user.
# Otherwise, exec whatever command was passed through (e.g. from a child image's
# own CMD, or `docker run <image> some-other-command`), still as that user.
if [ "$1" = "dropboxd" ]; then
    exec su -s /bin/sh "${USERACCOUNT}" -c "exec ${HOME_DIR}/.dropbox-dist/dropboxd"
else
    exec su -s /bin/sh "${USERACCOUNT}" -c "exec $*"
fi