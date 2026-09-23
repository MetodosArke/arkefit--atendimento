#!/usr/bin/env bash
# Backup do banco do Chatwoot e dos anexos (fotos e documentos que os clientes mandam ficam fora do banco,
# na pasta storage). Guarda em /var/backups/arkefit-atendimento e mantém os 7 mais recentes de cada.
#
# Restaurar o banco:
#   gunzip -c chatwoot-<data>.sql.gz | docker compose exec -T postgres psql -U "$POSTGRES_USER" -d chatwoot
# Restaurar os anexos:
#   docker compose run --rm --no-deps -v /var/backups/arkefit-atendimento:/origem --entrypoint tar \
#     chatwoot-rails xzf /origem/anexos-<data>.tar.gz -C /app
set -euo pipefail

cd "$(dirname "$0")/.."
. ./.env

destino=/var/backups/arkefit-atendimento
carimbo=$(date +%Y%m%d-%H%M)
mkdir -p "$destino"
chmod 700 "$destino"

docker compose exec -T postgres pg_dump -U "$POSTGRES_USER" -d chatwoot --clean --if-exists \
  | gzip > "$destino/chatwoot-$carimbo.sql.gz"

docker compose run --rm --no-deps -v "$destino:/destino" --entrypoint tar chatwoot-rails \
  czf "/destino/anexos-$carimbo.tar.gz" -C /app storage

for prefixo in chatwoot anexos; do
  ls -1t "$destino/$prefixo-"* 2>/dev/null | tail -n +8 | xargs -r rm -f
done

echo "$(date -Is) backup ok em $destino"
