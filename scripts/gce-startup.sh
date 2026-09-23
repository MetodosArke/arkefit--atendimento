#!/usr/bin/env bash
# Script de inicialização da VM no Google Compute Engine (metadado "startup-script").
# Roda a cada boot, mas só instala no primeiro: depois disso os containers voltam sozinhos
# (restart: unless-stopped), e reinstalar a cada boot atualizaria as imagens sem ninguém pedir.
set -euo pipefail

# O marcador só é gravado com a instalação concluída: se ela falhar no meio, o próximo boot tenta de novo.
pasta=/opt/arkefit-atendimento
marcador=/var/lib/arkefit-atendimento.instalado
[ -f "$marcador" ] && exit 0

apt-get update -y
apt-get install -y git curl openssl
[ -d "$pasta/.git" ] || git clone https://github.com/MetodosArke/arkefit--atendimento.git "$pasta"
bash "$pasta/scripts/instalar.sh" > /var/log/arkefit-instalacao.log 2>&1
touch "$marcador"
