# ArkeFit Atendimento

Canal de suporte via WhatsApp para as academias clientes do ArkeFit. Sistema independente do
`arke-system`: não compartilha banco, código nem infraestrutura. A única ligação é o link do WhatsApp
de suporte, que o ArkeFit mostra aos clientes (ver o fim deste arquivo).

- **Evolution API** conecta um número de WhatsApp (pelo protocolo do WhatsApp Web, sem API oficial da Meta).
- **Chatwoot** é onde a equipe lê e responde, e onde cada conversa é atribuída a quem vai atender.
- **Caddy** publica os dois com HTTPS automático. **Postgres** e **Redis** guardam os dados.

## O que providenciar

| Item | Observação |
|---|---|
| Servidor Ubuntu 22.04/24.04, 2 vCPU / 4 GB RAM, IP fixo | Portas 80 e 443 abertas. Menos de 4 GB não sustenta o Chatwoot. O IP precisa ser fixo: o endereço de acesso é derivado dele. |
| Chip de WhatsApp dedicado ao suporte | Não use número pessoal: a conexão não é a API oficial e, em caso de bloqueio, perde-se o número. |
| *(opcional)* E-mail para envio (SMTP) | Sem ele tudo funciona, só não saem e-mails do Chatwoot. Ver `.env.example`. |

Não precisa comprar domínio: o `sslip.io` transforma o IP do servidor num endereço
(`chatwoot.203-0-113-10.sslip.io`). O instalador monta isso e gera todas as senhas internas, que ficam
só no `.env` do servidor.

## Instalar

No servidor, como root:

```bash
git clone https://github.com/MetodosArke/arkefit--atendimento.git /opt/arkefit-atendimento
bash /opt/arkefit-atendimento/scripts/instalar.sh
```

Não pede nada. A primeira subida baixa as imagens e cria o banco — alguns minutos;
`docker compose logs -f` mostra o andamento. No fim, o script mostra o endereço do Chatwoot.

### No Google Compute Engine

O `scripts/gce-startup.sh` faz a instalação acima sozinho no primeiro boot da VM. Configuração usada:

| Campo | Valor |
|---|---|
| Região | `southamerica-east1` (São Paulo) |
| Máquina | `e2-medium` (2 vCPU, 4 GB) |
| Disco | Ubuntu 24.04 LTS, 30 GB balanceado |
| IP externo | **estático reservado** — IP efêmero muda ao parar a VM e o endereço de acesso muda junto |
| Rede | tags `http-server` e `https-server` (liberam 80 e 443) |
| Metadado `startup-script` | conteúdo de `scripts/gce-startup.sh` |

O log da instalação fica em `/var/log/arkefit-instalacao.log`.

## Primeiro acesso

1. Abra o endereço mostrado pelo instalador e crie a conta de administrador.
2. Para o segundo atendente: **Configurações → Agentes → Adicionar agente**. O convite vai por e-mail —
   sem SMTP configurado, crie o usuário com senha pelo painel de super administrador, em `/super_admin`.

## Conectar o WhatsApp

1. No Chatwoot, avatar → **Configurações do perfil** → copie o **Token de acesso**.
2. No servidor: `bash /opt/arkefit-atendimento/scripts/conectar-whatsapp.sh <token>`
3. No Chatwoot aparece a caixa **WhatsApp Suporte** com uma conversa contendo o QR Code.
   Escaneie no celular do número de suporte: **Aparelhos conectados → Conectar um aparelho**.

A partir daí toda mensagem recebida vira conversa no Chatwoot, e a resposta digitada lá sai pelo WhatsApp.

## Distribuir o atendimento

Em **Configurações → Caixas de entrada → WhatsApp Suporte → Colaboradores**, inclua os dois agentes e ligue
**Atribuição automática**: as conversas novas se alternam entre vocês. Para mandar uma conversa específica para
o outro, use o campo **Atribuído a** dentro dela.

## Backup

O instalador agenda `scripts/backup.sh` todo dia às 03:00: os dois bancos e a sessão do WhatsApp, em
`/var/backups/arkefit-atendimento`, mantendo os 7 mais recentes. A sessão entra porque, sem ela, é preciso
escanear o QR Code de novo. O backup fica no próprio servidor — protege de erro e corrupção, não da perda
do servidor; para isso, use snapshots do disco no provedor. O cabeçalho do script mostra como restaurar.

## Operação

```bash
cd /opt/arkefit-atendimento
docker compose ps              # estado dos serviços
docker compose logs -f <nome>  # logs (evolution-api, chatwoot-rails, …)
git pull && docker compose pull && docker compose up -d   # atualizar
```

O `chatwoot-prepare` roda a cada subida e aplica as migrations de uma versão nova; ele aparece como
"Exited (0)" — é o esperado.

## Ligação com o ArkeFit

Quando o número estiver conectado, cadastre o link `https://wa.me/55DDDNUMERO` como canal de suporte em
**ArkeFit → Visão Master → Configurações**. É ele que alimenta o botão "falar com o suporte" do onboarding
das academias.

## Próximo passo

Chatbot para dúvidas simples (conta OpenAI já existente), respondendo antes de passar para uma pessoa.
