#!/bin/bash
# bbk visuals – Start auf dem Mac (Doppelklick; beim ersten Mal: Rechtsklick → Öffnen)
cd "$(dirname "$0")" || exit 1

open_chrome() {
  if [ -d "/Applications/Google Chrome.app" ]; then open -a "Google Chrome" "$1"; else open "$1"; fi
}

# python3 nur nehmen, wenn es wirklich installiert ist – sonst fragt macOS nach den Entwicklertools
PY=""
for p in /opt/homebrew/bin/python3 /usr/local/bin/python3 /Library/Frameworks/Python.framework/Versions/Current/bin/python3; do
  if [ -x "$p" ]; then PY="$p"; break; fi
done
if [ -z "$PY" ] && xcode-select -p >/dev/null 2>&1; then PY=/usr/bin/python3; fi

if [ -z "$PY" ]; then
  echo "Kein Python gefunden – starte direkt aus dem Ordner (braucht Internet)."
  open_chrome "index.html"
  exit 0
fi

PORT=8080
while lsof -i :"$PORT" >/dev/null 2>&1; do PORT=$((PORT + 1)); done
echo "bbk visuals läuft auf http://localhost:$PORT/  (Fenster offen lassen, schließen = beenden)"
( sleep 1; open_chrome "http://localhost:$PORT/" ) &

exec "$PY" - "$PORT" <<'EOF'
import sys, http.server
H = http.server.SimpleHTTPRequestHandler
H.extensions_map.update({".mjs": "text/javascript", ".js": "text/javascript", ".wasm": "application/wasm",
                         ".woff2": "font/woff2", ".css": "text/css", ".tflite": "application/octet-stream"})
H.log_message = lambda *a: None
http.server.ThreadingHTTPServer(("127.0.0.1", int(sys.argv[1])), H).serve_forever()
EOF
