#!/usr/bin/env bash
# Cria a instância do WhatsApp na Evolution API já ligada ao Chatwoot. Rodar no VPS, na pasta do repositório:
#   bash scripts/conectar-whatsapp.sh <TOKEN_DO_CHATWOOT> [ID_DA_CONTA]
#
# TOKEN_DO_CHATWOOT: no Chatwoot, clique no seu avatar → Configurações do perfil → "Token de acesso".
# ID_DA_CONTA: o número que aparece na URL do Chatwoot (/app/accounts/1/...). Padrão: 1.
#
# A Evolution cria sozinha a caixa "WhatsApp Suporte" no Chatwoot e manda o QR Code como
# mensagem numa conversa dessa caixa. Escaneie pelo WhatsApp do número de suporte:
# Aparelhos conectados → Conectar um aparelho.
set -euo pipefail

cd "$(dirname "$0")/.."

token="${1:?Informe o token de acesso do Chatwoot (veja o comentário no topo do script)}"
conta="${2:-1}"
. ./.env

curl -fsS -X POST "https://$EVOLUTION_DOMAIN/instance/create" \
  -H "apikey: $EVOLUTION_API_KEY" \
  -H "Content-Type: application/json" \
  -d @- <<JSON
{
  "instanceName": "suporte",
  "integration": "WHATSAPP-BAILEYS",
  "qrcode": true,
  "chatwootAccountId": "$conta",
  "chatwootToken": "$token",
  "chatwootUrl": "https://$CHATWOOT_DOMAIN",
  "chatwootNameInbox": "WhatsApp Suporte",
  "chatwootSignMsg": true,
  "chatwootReopenConversation": true,
  "chatwootConversationPending": false,
  "chatwootMergeBrazilContacts": true,
  "chatwootImportContacts": false,
  "chatwootImportMessages": false,
  "chatwootAutoCreate": true
}
JSON
echo
echo "Instância criada. Abra o Chatwoot: a caixa \"WhatsApp Suporte\" terá uma conversa com o QR Code."
