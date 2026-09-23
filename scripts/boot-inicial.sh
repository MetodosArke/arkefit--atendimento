#!/usr/bin/env bash
# Instalação automática no primeiro boot de um servidor novo. Cole o conteúdo como script de
# inicialização ao criar a instância (Oracle: "Script cloud-init"; outros provedores: "user data").
# No cloud-init ele roda uma vez só; se a instalação falhar, rode scripts/instalar.sh pelo SSH.
set -euo pipefail

# O marcador só é gravado com a instalação concluída.
pasta=/opt/arkefit-atendimento
marcador=/var/lib/arkefit-atendimento.instalado
[ -f "$marcador" ] && exit 0

# No primeiro boot o Ubuntu costuma estar rodando a atualização automática, que segura a trava do apt.
# Esperar por ela (inclusive dentro do instalador do Docker) em vez de falhar na hora.
echo 'DPkg::Lock::Timeout "900";' > /etc/apt/apt.conf.d/99espera-trava
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y git curl openssl
[ -d "$pasta/.git" ] || git clone https://github.com/MetodosArke/arkefit--atendimento.git "$pasta"
bash "$pasta/scripts/instalar.sh" > /var/log/arkefit-instalacao.log 2>&1
touch "$marcador"
