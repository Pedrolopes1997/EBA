#!/bin/bash
# Instala o ATUALIZADOR AUTOMÁTICO do portal EBA (rodar UMA vez, no servidor, com sudo):
#   sudo bash /opt/eba/eba-cuiaba-sul/instalar-atualizador.sh
# Depois disso as versões novas enviadas pela WeCare entram sozinhas (a cada 5 minutos), só se estiverem
# assinadas pela WeCare, e voltam sozinhas para a anterior se o site não responder.
# Para desligar: sudo systemctl disable --now eba-atualizar.timer
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
DIR=${EBA_DIR:-$HERE}
APP_USER=${EBA_USER:-$(stat -c %U "$DIR")}
SERVICE=${EBA_SERVICE:-eba}
ROOT=${EBA_INSTALL_ROOT:-}            # só para testes: instala dentro de outra pasta e não mexe no systemd

[ "$(id -u)" = 0 ] || { echo "Rode com sudo: sudo bash $0"; exit 1; }
for c in git curl ssh-keygen runuser flock logger; do command -v $c >/dev/null || { echo "Falta o programa $c no servidor."; exit 1; }; done
[ -d "$DIR/.git" ] || { echo "Pasta do portal não encontrada em $DIR"; exit 1; }
[ -n "$ROOT" ] || systemctl cat "$SERVICE" >/dev/null 2>&1 || { echo "Serviço '$SERVICE' não encontrado (use EBA_SERVICE=nome)."; exit 1; }

install -d -m 755 "$ROOT/etc/eba" "$ROOT/usr/local/bin" "$ROOT/etc/systemd/system"
install -m 644 "$HERE/assinatura-wecare.pub" "$ROOT/etc/eba/assinatura-wecare"
printf 'EBA_DIR=%q\nEBA_USER=%q\nEBA_SERVICE=%q\n' "$DIR" "$APP_USER" "$SERVICE" > "$ROOT/etc/eba/atualizador.conf"
chmod 644 "$ROOT/etc/eba/atualizador.conf"
install -m 755 "$HERE/eba-atualizar" "$ROOT/usr/local/bin/eba-atualizar"

cat > "$ROOT/etc/systemd/system/eba-atualizar.service" <<'EOF'
[Unit]
Description=EBA Cuiabá Sul — atualizador automático (WeCare Consultoria)
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/eba-atualizar
EOF
cat > "$ROOT/etc/systemd/system/eba-atualizar.timer" <<'EOF'
[Unit]
Description=EBA Cuiabá Sul — procura versão nova a cada 5 minutos

[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
RandomizedDelaySec=30

[Install]
WantedBy=timers.target
EOF

if [ -z "$ROOT" ]; then
  systemctl daemon-reload
  systemctl enable --now eba-atualizar.timer
  /usr/local/bin/eba-atualizar || true
  echo
  echo "✓ Atualizador automático instalado (portal: $DIR, usuário: $APP_USER, serviço: $SERVICE)."
  echo "  Próxima verificação: $(systemctl list-timers eba-atualizar.timer --no-legend | awk '{print $1, $2, $3}')"
  echo "  Registro: journalctl -t eba-atualizar"
else
  echo "✓ Instalado em $ROOT (modo de teste)."
fi
