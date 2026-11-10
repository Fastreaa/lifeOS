#!/usr/bin/env bash
# Guarda y sube todo el trabajo. Úsalo al terminar cada sesión:
#   bash scripts/guardar.sh "qué hice hoy"
# Al final borra el token de la memoria: el siguiente push lo volverá a pedir.

set -euo pipefail
cd "$(dirname "$0")/.."

MESSAGE="${1:-Avance $(date '+%Y-%m-%d %H:%M')}"

git add -A
if git diff --cached --quiet; then
  echo "No hay cambios nuevos que guardar."
else
  git commit -m "$MESSAGE"
fi

GIT_ASKPASS= SSH_ASKPASS= git -c core.askpass= push
git credential-cache exit 2>/dev/null || true
echo "Listo: guardado y subido a GitHub."
