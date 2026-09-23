#!/usr/bin/env bash
# Backup dos dois bancos (Chatwoot e Evolution) e da sessão do WhatsApp.
# Guarda em /var/backups/arkefit-atendimento e mantém os 7 mais recentes.
# A sessão importa tanto quanto o banco: sem ela, é preciso escanear o QR Code de novo.
#
# Restaurar um banco:
#   gunzip -c <arquivo>.sql.gz | docker compose exec -T postgres psql -U "$POSTGRES_USER" -d <chatwoot|evolution>
set -euo pipefail

cd "$(dirname "$0")/.."
. ./.env

destino=/var/backups/arkefit-atendimento
carimbo=$(date +%Y%m%d-%H%M)
mkdir -p "$destino"
chmod 700 "$destino"

for banco in chatwoot evolution; do
  docker compose exec -T postgres pg_dump -U "$POSTGRES_USER" -d "$banco" --clean --if-exists \
    | gzip > "$destino/$banco-$carimbo.sql.gz"
done

docker compose run --rm --no-deps -v "$destino:/destino" --entrypoint tar evolution-api \
  czf "/destino/whatsapp-sessao-$carimbo.tar.gz" -C /evolution instances

# Mantém os 7 mais recentes de cada tipo.
for prefixo in chatwoot evolution whatsapp-sessao; do
  ls -1t "$destino/$prefixo-"* 2>/dev/null | tail -n +8 | xargs -r rm -f
done

echo "$(date -Is) backup ok em $destino"
