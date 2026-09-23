# ArkeFit Atendimento

Canal de suporte via WhatsApp para as academias clientes do ArkeFit. Sistema independente do
`arke-system`: não compartilha banco, código nem infraestrutura. A única ligação é o link do WhatsApp
de suporte, que o ArkeFit mostra aos clientes (ver o fim deste arquivo).

- **Chatwoot** recebe as mensagens pela API oficial da Meta (WhatsApp Cloud API) e é onde a equipe lê,
  responde e distribui as conversas.
- **Caddy** publica o Chatwoot com HTTPS automático. **Postgres** e **Redis** guardam os dados.

O número usa **coexistência**: continua funcionando no aplicativo WhatsApp Business do celular e, ao mesmo
tempo, na API. O Chatwoot suporta isso — não registra o número de novo (o que quebraria a coexistência) e
mostra também as respostas dadas pelo celular. Pelo mesmo motivo, bibliotecas que imitam o WhatsApp Web
(Evolution API, Baileys) **não funcionam** nesse número: a Meta tira da mensagem o que elas precisam para
decifrá-la.

## O que providenciar

| Item | Observação |
|---|---|
| Servidor Ubuntu 22.04/24.04 com pelo menos 4 GB de RAM | Gratuito na Oracle Cloud (ver abaixo). Portas 80 e 443 abertas. O IP não pode mudar: o endereço de acesso é derivado dele. |
| Acesso à conta Meta Business do número | Para gerar o token e ler os IDs (ver "Conectar o WhatsApp"). |
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

**1. Na Meta**, reunir quatro dados:

| Dado | Onde |
|---|---|
| Número com DDI | ex.: `+5511999999999` |
| ID do número de telefone | Gerenciador do WhatsApp → Números de telefone → o número; ou painel do app → WhatsApp → Configuração da API |
| ID da conta do WhatsApp Business (WABA) | mesmo lugar |
| Token permanente | Configurações do negócio → Usuários do sistema → Adicionar (função Administrador) → Atribuir ativos: a conta do WhatsApp (controle total) e o app → Gerar token: validade **Nunca**, permissões `whatsapp_business_messaging` e `whatsapp_business_management` |

O token dá acesso à conta do WhatsApp inteira: trate como senha, e só cole no Chatwoot.

**2. No Chatwoot**: Configurações → Caixas de entrada → Adicionar caixa de entrada → WhatsApp → provedor
**WhatsApp Cloud**. Nome `WhatsApp Suporte` e os quatro dados acima (o token vai em "Chave de API").

Ao salvar, o próprio Chatwoot aponta o webhook **deste número** para ele. Se hoje outro sistema recebe as
mensagens desse número, ele para de receber. Se o apontamento automático falhar, a tela da caixa mostra a
URL de callback e o token de verificação para colar à mão no painel do app → WhatsApp → Configuração → Webhook
(assinando os campos `messages` e `smb_message_echoes`).

**3. Testar**: mande uma mensagem de outro celular para o número. Ela aparece no Chatwoot e continua
aparecendo no aplicativo do celular.

**Janela de 24 horas.** Pela regra da Meta, a resposta livre só vale até 24 h depois da última mensagem do
cliente, e dentro dela é gratuita. Depois disso só sai mensagem com modelo aprovado, que é cobrada. Num canal
de suporte que só responde, isso quase não aparece; quando aparecer, o Chatwoot avisa na conversa.

## Distribuir o atendimento

Em **Configurações → Caixas de entrada → WhatsApp Suporte → Colaboradores**, inclua os dois agentes e ligue
**Atribuição automática**: as conversas novas se alternam entre vocês. Para mandar uma conversa específica para
o outro, use o campo **Atribuído a** dentro dela. Responder pelo celular também funciona e fica registrado no
Chatwoot, mas a atribuição só existe no Chatwoot.

## Backup

O instalador agenda `scripts/backup.sh` todo dia às 03:00: o banco do Chatwoot e os anexos (fotos e
documentos dos clientes ficam fora do banco), em `/var/backups/arkefit-atendimento`, mantendo os 7 mais
recentes. O backup fica no próprio servidor — protege de erro e corrupção, não da perda
do servidor; para isso, use snapshots do disco no provedor. O cabeçalho do script mostra como restaurar.

## Operação

```bash
cd /opt/arkefit-atendimento
docker compose ps              # estado dos serviços
docker compose logs -f <nome>  # logs (chatwoot-rails, chatwoot-sidekiq, caddy, …)
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
