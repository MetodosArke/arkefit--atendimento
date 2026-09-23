#!/usr/bin/env bash
# Instalação automática no primeiro boot de um servidor novo. Cole o conteúdo como script de
# inicialização ao criar a instância (Oracle: "Script cloud-init"; outros provedores: "user data").
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
