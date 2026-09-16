# ArkeFit Atendimento

Plataforma de atendimento via WhatsApp para clientes que já adquiriram o ArkeFit.
Sistema independente do `arke-system` — sem correlação de banco, código ou infraestrutura.

Stack: **Evolution API** (conecta o número de WhatsApp, somente recebimento/envio de conversa)
+ **Chatwoot** (inbox onde você e seu sócio atendem e distribuem as conversas entre si).

## O que você precisa providenciar

### 1. VPS
Provisione um servidor (Hetzner, DigitalOcean, Contabo etc.) com:
- Ubuntu 22.04 (ou similar)
- Docker + Docker Compose instalados (`curl -fsSL https://get.docker.com | sh`)
- Portas 80 e 443 liberadas no firewall
- Pelo menos 2 vCPU / 4 GB RAM (Chatwoot é o mais pesado dos dois)

Anote o **IP público** do servidor — vai ser usado no domínio gratuito (passo 2).

### 2. Domínio (gratuito, via sslip.io)
Não precisa comprar nada. O `sslip.io` resolve automaticamente qualquer nome no formato
`algo.SEU-IP-COM-HIFEN.sslip.io` para o IP embutido no próprio nome.

Exemplo: se o IP do VPS for `203.0.113.10`, use:
- `chatwoot.203-0-113-10.sslip.io`
- `evolution.203-0-113-10.sslip.io`

Preencha isso em `CHATWOOT_DOMAIN` e `EVOLUTION_DOMAIN` no `.env`.

### 3. Segredos e senhas (gerados por você, localmente)
Rode estes comandos no terminal e cole cada resultado no `.env`:

```bash
openssl rand -hex 24   # -> POSTGRES_PASSWORD
openssl rand -hex 24   # -> REDIS_PASSWORD
openssl rand -hex 64   # -> CHATWOOT_SECRET_KEY_BASE
openssl rand -hex 32   # -> EVOLUTION_API_KEY
```

### 4. E-mail SMTP (para o Chatwoot mandar convite/redefinição de senha)
Use uma conta de e-mail dedicada. Caminho mais rápido com Gmail:
1. Crie (ou use) uma conta Gmail só para isso.
2. Ative a verificação em duas etapas na conta Google.
3. Gere uma "Senha de app" em https://myaccount.google.com/apppasswords
4. Preencha `SMTP_USERNAME` (o e-mail) e `SMTP_PASSWORD` (a senha de app gerada) no `.env`.

## Como subir o sistema

```bash
# 1. Clonar e entrar na pasta (já feito se você está lendo isso no repo)
cp .env.example .env
nano .env   # preencha com os valores dos passos acima

# 2. Subir os containers
docker compose up -d

# 3. Acompanhar os logs até tudo ficar saudável
docker compose logs -f
```

## Primeiro acesso

1. Abra `https://SEU_CHATWOOT_DOMAIN` — a primeira tela pede para criar a conta admin (seu usuário).
2. Dentro do Chatwoot, crie um segundo agente para o seu sócio (Configurações → Agentes → Adicionar agente).
3. Abra `https://SEU_EVOLUTION_DOMAIN` (ou use a API) com o header `apikey: SEU_EVOLUTION_API_KEY` para criar uma instância e obter o QR Code — escaneie com o WhatsApp que vai ser o número de atendimento (recomendo um chip dedicado, não o pessoal).
4. No Chatwoot, crie um canal do tipo "API" e conecte com a instância da Evolution API (webhook da Evolution API aponta para a URL do canal no Chatwoot). Isso liga as duas pontas: mensagem chega no WhatsApp → aparece na inbox do Chatwoot → você ou seu sócio assume a conversa.

## Próximos passos (fora do escopo desta primeira etapa)
- Chatbot de IA para dúvidas simples (usando a conta OpenAI que você já possui) — entra depois que o fluxo manual estiver validado.
