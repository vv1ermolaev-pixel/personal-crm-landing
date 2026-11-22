#!/usr/bin/env bash
# Installs the landing nginx site (funkicrm-landing.conf next to this script).
# Run on the server as root: sudo bash install.sh
#
# 1. Copies funkicrm-landing.conf to sites-available and enables it.
# 2. Removes the old landing block from the shared funkicrm.conf (once; the app
#    and catch-all blocks there are not touched). Backup: funkicrm.conf.bak-<date>.
# 3. nginx -t; if it fails, everything goes back as it was. Then reload.
# Safe to run again: it only replaces the landing site file.
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)/funkicrm-landing.conf"
SITE="/etc/nginx/sites-available/funkicrm-landing.conf"
LINK="/etc/nginx/sites-enabled/funkicrm-landing.conf"
SHARED="/etc/nginx/sites-available/funkicrm.conf"

[ "$(id -u)" = 0 ] || { echo "Run as root: sudo bash $0" >&2; exit 1; }
[ -f "$SRC" ] || { echo "Not found: $SRC" >&2; exit 1; }

stamp="$(date +%Y%m%d-%H%M%S)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Snapshot of what we may change, to restore on failure
cp -a "$SHARED" "$tmp/shared"
had_site=0; [ -f "$SITE" ] && { cp -a "$SITE" "$tmp/site"; had_site=1; }
had_link=0; [ -L "$LINK" ] && had_link=1

restore() {
  cp -a "$tmp/shared" "$SHARED"
  if [ "$had_site" = 1 ]; then cp -a "$tmp/site" "$SITE"; else rm -f "$SITE"; fi
  [ "$had_link" = 1 ] || rm -f "$LINK"
  echo "Nothing changed: previous nginx config restored" >&2
}

install -m 644 -o root -g root "$SRC" "$SITE"
ln -sfn "$SITE" "$LINK"

# The old landing block in the shared file, exactly as server-setup.sh wrote it
if grep -qF 'root /var/www/funkicrm.ru;' "$SHARED"; then
  cp -a "$SHARED" "$SHARED.bak-$stamp"
  perl -0pi -e '
    s{^# Лендинг\nserver \{\n    listen 443 ssl http2;\n    server_name funkicrm\.ru;\n    include snippets/funkicrm-cert\.conf;\n    root /var/www/funkicrm\.ru;\n    index index\.html;\n    location / \{ try_files \$uri \$uri/ =404; \}\n\}\n}{# Landing funkicrm.ru: own file funkicrm-landing.conf (personal-crm-landing repo, deploy/nginx/)\n}m
  ' "$SHARED"
  if grep -qF 'root /var/www/funkicrm.ru;' "$SHARED"; then
    restore
    rm -f "$SHARED.bak-$stamp"
    echo "The landing block in $SHARED has an unexpected shape" >&2
    exit 1
  fi
  echo "Old landing block removed from $SHARED (backup: $SHARED.bak-$stamp)"
fi

if ! nginx -t; then
  restore
  exit 1
fi
systemctl reload nginx
echo "Landing nginx site installed and nginx reloaded"
