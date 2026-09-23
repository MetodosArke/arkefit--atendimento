# ArkeFit Atendimento

Canal de suporte via WhatsApp para as academias clientes do ArkeFit. Sistema independente do
`arke-system`: não compartilha banco, código nem infraestrutura. A única ligação é o link do WhatsApp
de suporte, que o ArkeFit mostra aos clientes (ver o fim deste arquivo).

- **Evolution API** conecta um número de WhatsApp (pelo protocolo do WhatsApp Web, sem API oficial da Meta).
- **Chatwoot** é onde a equipe lê e responde, e onde cada conversa é atribuída a quem vai atender.
- **Caddy** publica os dois com HTTPS automático. **Postgres** e **Redis** guardam os dados.

## O que providenciar

| Item | Onde | Observação |
|---|---|---|
| VPS Ubuntu 22.04 ou 24.04, 2 vCPU / 4 GB RAM | Hetzner, DigitalOcean, Contabo… | Portas 80 e 443 abertas. Anote o IP e a senha de root. |
| Chip de WhatsApp dedicado ao suporte | Qualquer operadora | Não use número pessoal: a conexão não é a API oficial e, em caso de bloqueio, perde-se o número. |
| E-mail para envio (SMTP) | Conta Gmail dedicada | Ative a verificação em duas etapas e gere uma [senha de app](https://myaccount.google.com/apppasswords). |

Não precisa comprar domínio: o `sslip.io` transforma o IP do servidor num endereço
(`chatwoot.203-0-113-10.sslip.io`), e o script monta isso sozinho. As senhas internas
(Postgres, Redis, chaves) também são geradas pelo script e ficam só no `.env` do servidor.

## Instalar

No servidor, como root:

```bash
git clone https://github.com/MetodosArke/arkefit--atendimento.git
cd arkefit--atendimento
bash scripts/instalar.sh     # gera o .env e para, pedindo o SMTP
nano .env                    # preencha LETSENCRYPT_EMAIL e o bloco SMTP
bash scripts/instalar.sh     # agora sobe tudo
```

A primeira subida baixa as imagens e cria o banco — alguns minutos. `docker compose logs -f` mostra o andamento.

## Primeiro acesso

1. Abra o endereço que o script mostrou e crie a conta de administrador.
2. **Configurações → Agentes → Adicionar agente**: convide seu sócio. Ele recebe o convite por e-mail.

## Conectar o WhatsApp

1. No Chatwoot, avatar → **Configurações do perfil** → copie o **Token de acesso**.
2. No servidor: `bash scripts/conectar-whatsapp.sh <token>`
3. No Chatwoot aparece a caixa **WhatsApp Suporte** com uma conversa contendo o QR Code.
   Escaneie no celular do número de suporte: **Aparelhos conectados → Conectar um aparelho**.

A partir daí toda mensagem recebida vira conversa no Chatwoot, e a resposta digitada lá sai pelo WhatsApp.

## Distribuir o atendimento

Em **Configurações → Caixas de entrada → WhatsApp Suporte → Colaboradores**, inclua os dois agentes e ligue
**Atribuição automática**: as conversas novas se alternam entre vocês. Para mandar uma conversa específica para
o outro, use o campo **Atribuído a** dentro dela.

## Operação

```bash
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
