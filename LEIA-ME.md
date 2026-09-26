# EBA Cuiabá Sul 2026 — Como instalar

Este é um **pacote pronto**. Você só precisa colocá-lo no servidor e preencher o arquivo `.env`.

> ⚠️ **Não altere, apague nem renomeie nenhum arquivo do pacote** (a não ser o `.env` que você vai criar).
> Os arquivos são verificados automaticamente: se algum for mudado, o portal mostra "Portal em manutenção" e para de funcionar.
> Para corrigir, basta colocar de novo os arquivos do pacote original.

## 1. O que o servidor precisa ter

- Linux com acesso SSH (ex.: VPS ou Cloud Server da Locaweb). Hospedagem que só roda PHP **não** serve.
- **Node.js 20 ou mais novo** (`node -v` para conferir).
- **nginx** com **HTTPS** (certificado Let's Encrypt).
- Uma conta de e-mail com **SMTP** (servidor, porta, usuário e senha) para enviar as confirmações.
- Um domínio apontando para o servidor.

## 2. Colocar o pacote no servidor

Baixe direto do GitHub (ou, se recebeu um `.zip`, descompacte-o com `unzip`):

```bash
git clone https://github.com/Pedrolopes1997/EBA.git eba-cuiaba-sul
cd eba-cuiaba-sul
```

Versão nova do pacote: `git pull` dentro da pasta e reinicie o serviço.

Não precisa rodar `npm install`: tudo já vem dentro do pacote.

## 3. Criar o `.env`

```bash
cp .env.example .env
chmod 600 .env
nano .env
```

Preencha **só** o que está no arquivo: endereço do site (`SITE_URL`), porta e os dados de e-mail (`MAIL_*`).
A conta que recebe os pagamentos e as regras do evento já vêm definidas no pacote e não mudam pelo `.env`.

## 4. Deixar o portal rodando

Crie `/etc/systemd/system/eba.service` (troque USUARIO e o caminho):

```ini
[Unit]
Description=EBA Cuiabá Sul 2026
After=network.target

[Service]
Type=simple
User=USUARIO
WorkingDirectory=/caminho/para/eba-cuiaba-sul
ExecStart=/usr/bin/node app.cjs
Restart=always
RestartSec=5
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now eba
sudo systemctl status eba      # deve mostrar "active (running)"
```

## 5. nginx com HTTPS

```nginx
server {
    server_name eba.seudominio.com.br;
    client_max_body_size 1m;
    location / {
        proxy_pass http://127.0.0.1:3006;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
sudo nginx -t && sudo systemctl reload nginx
sudo certbot --nginx -d eba.seudominio.com.br
```

## 6. Pronto — avise a WeCare Consultoria

Quando `https://SEU_DOMINIO/` abrir, avise a WeCare Consultoria. O **primeiro acesso ao painel** (`/admin`) é feito pelo responsável do sistema; se você precisar de acesso (por exemplo, para a portaria no dia do evento), ele cria a sua conta.

## Problemas comuns

| O que aparece | O que fazer |
|---|---|
| "Portal em manutenção — arquivos alterados" | Algum arquivo do pacote foi mudado. Coloque de novo os arquivos do pacote original (mantenha a pasta `data/` e o `.env`) e reinicie: `sudo systemctl restart eba` |
| Site não abre / erro 502 | `sudo systemctl status eba` e confira se a porta do nginx é a mesma do `.env` |
| E-mails não chegam | Confira os dados `MAIL_*` e se o `MAIL_FROM` é a própria conta de e-mail |
| Câmera da portaria não abre | O site precisa estar em **https** |

**Importante:** a pasta `data/` guarda as inscrições. Não apague, e faça cópia dela de vez em quando.

Suporte: contato@wecareconsultoria.com.br
