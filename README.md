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
| Servidor Ubuntu 22.04/24.04 com pelo menos 4 GB de RAM | Gratuito na Oracle Cloud (ver abaixo). Portas 80 e 443 abertas. O IP não pode mudar: o endereço de acesso é derivado dele. |
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

### Na Oracle Cloud (camada gratuita)

A camada *Always Free* da Oracle roda a plataforma sem custo, em processador ARM — todas as imagens usadas
têm versão ARM. O `scripts/boot-inicial.sh`, colado como script de inicialização, faz a instalação acima
sozinho no primeiro boot.

1. **Criar a conta** em oracle.com/cloud/free. A **região inicial é definitiva** e a instância gratuita só
   existe nela: escolha **Brazil East (São Paulo)**. O cadastro pede cartão, só para verificação.
2. **Liberar as portas** — Rede → Redes virtuais (VCN) → a VCN padrão → Lista de segurança padrão →
   Adicionar regras de entrada: origem `0.0.0.0/0`, TCP, portas de destino `80` e depois `443`.
3. **Criar a instância** — Computação → Instâncias → Criar:

| Campo | Valor |
|---|---|
| Imagem | Canonical Ubuntu 24.04 (a versão aarch64 aparece ao escolher a forma abaixo) |
| Forma | Ampere → `VM.Standard.A1.Flex`, **1 OCPU e 6 GB** |
| Rede | VCN padrão, sub-rede pública, com endereço IPv4 público |
| Chave SSH | "Gerar par de chaves" e **baixar a chave privada** — é o único acesso ao servidor |
| Script de inicialização | Mostrar opções avançadas → Gerenciamento → colar o conteúdo de `scripts/boot-inicial.sh` |

**Por que 1 OCPU e 6 GB, e não o máximo gratuito:** a Oracle recolhe instância gratuita que fica 7 dias com
CPU, rede **e** memória abaixo de 20%. Com 6 GB, a plataforma ocupa em torno de metade da memória e fica longe
desse limite; com 12 GB, fica perto dele. Converter a conta para *Pay As You Go* elimina o recolhimento e
continua sem custo dentro dos limites gratuitos.

Se aparecer **"Out of capacity"**, é falta de máquina ARM livre na região naquele momento: tente de novo mais
tarde. Em 5 a 10 minutos após a criação, a instalação termina; o endereço do Chatwoot é
`https://chatwoot.<IP-com-hífens>.sslip.io`, e o log fica em `/var/log/arkefit-instalacao.log`.

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
