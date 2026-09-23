#!/usr/bin/env bash
# Instala e sobe a plataforma num servidor Ubuntu. Rodar como root, na pasta do repositório:
#   bash scripts/instalar.sh
# Não pede nada: gera domínios e senhas sozinho. É seguro rodar de novo — não sobrescreve
# um .env existente, então as senhas e o endereço continuam os mesmos.
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

if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
  ufw allow 80/tcp && ufw allow 443/tcp
fi

# O Ubuntu da Oracle Cloud vem com regras de iptables que recusam tudo além do SSH.
if command -v netfilter-persistent >/dev/null 2>&1; then
  for porta in 80 443; do
    iptables -C INPUT -p tcp --dport "$porta" -j ACCEPT 2>/dev/null \
      || iptables -I INPUT -p tcp --dport "$porta" -j ACCEPT
  done
  netfilter-persistent save
fi

# Backup diário às 03:00 do servidor, guardando os últimos 7.
chmod +x scripts/backup.sh
linha_cron="0 3 * * * root $(pwd)/scripts/backup.sh >> /var/log/arkefit-backup.log 2>&1"
echo "$linha_cron" > /etc/cron.d/arkefit-backup

echo "→ Subindo os serviços (a primeira vez baixa as imagens e prepara o banco; leva alguns minutos)"
docker compose pull
docker compose up -d

. ./.env
echo
echo "Pronto. Abra https://$CHATWOOT_DOMAIN e crie a conta de administrador."
if [ -z "${SMTP_ADDRESS:-}" ]; then
  echo "Aviso: SMTP não configurado — o Chatwoot funciona, mas não envia e-mail (convite, redefinição de senha)."
  echo "Para ligar depois: preencha o bloco SMTP no .env e rode  docker compose up -d"
fi
