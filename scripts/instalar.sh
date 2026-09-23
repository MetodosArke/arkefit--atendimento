#!/usr/bin/env bash
# Instala e sobe a plataforma num VPS Ubuntu recém-criado. Rodar como root, na pasta do repositório:
#   bash scripts/instalar.sh
# É seguro rodar de novo: não sobrescreve um .env existente nem as senhas já geradas.
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v docker >/dev/null 2>&1; then
  echo "→ Instalando Docker"
  curl -fsSL https://get.docker.com | sh
fi

if [ ! -f .env ]; then
  echo "→ Gerando .env"
  ip=$(curl -fsS https://api.ipify.org)
  sufixo="$(echo "$ip" | tr . -).sslip.io"
  cp .env.example .env
  sed -i \
    -e "s|^CHATWOOT_DOMAIN=.*|CHATWOOT_DOMAIN=chatwoot.$sufixo|" \
    -e "s|^EVOLUTION_DOMAIN=.*|EVOLUTION_DOMAIN=evolution.$sufixo|" \
    -e "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$(openssl rand -hex 24)|" \
    -e "s|^REDIS_PASSWORD=.*|REDIS_PASSWORD=$(openssl rand -hex 24)|" \
    -e "s|^CHATWOOT_SECRET_KEY_BASE=.*|CHATWOOT_SECRET_KEY_BASE=$(openssl rand -hex 64)|" \
    -e "s|^EVOLUTION_API_KEY=.*|EVOLUTION_API_KEY=$(openssl rand -hex 32)|" \
    .env
  chmod 600 .env
fi

# Sem SMTP o Chatwoot sobe, mas não manda convite nem redefinição de senha.
if grep -qE '^(SMTP_PASSWORD=SENHA_DE_APP_AQUI|LETSENCRYPT_EMAIL=seu-email@exemplo.com)' .env; then
  echo
  echo "Falta preencher no .env: LETSENCRYPT_EMAIL e o bloco SMTP (MAILER_SENDER_EMAIL, SMTP_USERNAME, SMTP_PASSWORD)."
  echo "Edite com:  nano .env   e rode este script de novo."
  exit 1
fi

if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
  ufw allow 80/tcp && ufw allow 443/tcp
fi

echo "→ Subindo os serviços (a primeira vez baixa as imagens e prepara o banco; leva alguns minutos)"
docker compose pull
docker compose up -d

. ./.env
echo
echo "Pronto. Abra https://$CHATWOOT_DOMAIN e crie a conta de administrador."
echo "Depois siga o passo \"Conectar o WhatsApp\" do README."
