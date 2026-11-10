#!/bin/bash
# Ajuste do nginx do bodescuiabasul.com.br para o portal do MCB — WeCare Consultoria.
# Rodar no servidor (uma vez):
#   sudo /usr/local/bin/eba-atualizar; sudo bash /opt/eba/eba-cuiaba-sul/ajustar-nginx-portal.sh
# O que faz: deixa o site aceitar envios de até 64 MB (fotos e documentos do portal) e esperar até 5 minutos
# por respostas lentas. Guarda cópia dos arquivos antes; se o nginx não aceitar a mudança, volta tudo sozinho.
# Pode rodar mais de uma vez sem problema.
set -uo pipefail
DOMINIO=bodescuiabasul.com.br
NGINX=${AJUSTE_NGINX:-nginx}                        # (testes) outro nginx
RECARREGAR=${AJUSTE_RECARREGAR:-systemctl reload nginx}
PORTA=${AJUSTE_PORTA:-443}
BKBASE=${AJUSTE_BACKUP:-/root}
fim_erro() { echo; echo "✗ $1"; echo "  Mande uma foto desta tela para o Pedro."; exit 1; }

[ "$(id -u)" = 0 ] || [ -n "${AJUSTE_NGINX:-}" ] || { echo "Falta o sudo. Rode assim: sudo bash $0"; exit 1; }
command -v perl >/dev/null || fim_erro "não achei o programa perl neste servidor. Nada foi mudado."
$NGINX -t >/dev/null 2>&1 || fim_erro "o nginx já estava com erro ANTES do ajuste (nginx -t). Nada foi mudado."

# arquivos do nginx que configuram o domínio (o caminho real, não o atalho de sites-enabled)
mapfile -t ARQS < <($NGINX -T 2>/dev/null | awk -v d="$DOMINIO" '
  /^# configuration file / { f = $4; sub(/:$/, "", f) }
  $1 == "server_name" && index($0, d) { print f }' | while read -r a; do readlink -f "$a"; done | sort -u)
[ ${#ARQS[@]} -gt 0 ] || fim_erro "não achei a configuração do $DOMINIO no nginx. Nada foi mudado."

BK="$BKBASE/backup-nginx-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BK" || fim_erro "não consegui criar a pasta de cópia $BK. Nada foi mudado."
copia() { echo "$BK/$(echo "$1" | tr / _)"; }
for a in "${ARQS[@]}"; do cp -p "$a" "$(copia "$a")" || fim_erro "não consegui copiar $a. Nada foi mudado."; done
voltar() { for a in "${ARQS[@]}"; do cat "$(copia "$a")" > "$a"; done; }
echo "Arquivo(s) do site: ${ARQS[*]}"
echo "Cópia de segurança: $BK"

# troca/acrescenta as 3 linhas logo abaixo de "server_name ... bodescuiabasul.com.br" em cada bloco do site
cat > "$BK/editar.pl" <<'PERL'
use strict; use warnings;
my ($f, $dom) = @ARGV;
open(my $in, '<', $f) or die "não abri $f: $!\n";
my @L = <$in>; close $in;
my (@blocos, @pilha); my $prof = 0;
for my $i (0 .. $#L) {
  (my $c = $L[$i]) =~ s/#.*//s;
  my $abre = () = $c =~ /\{/g; my $fecha = () = $c =~ /\}/g;
  push @pilha, [$i, $prof] if $c =~ /^\s*server\s*(\{|$)/;
  $prof += $abre - $fecha;
  if (@pilha && $prof == $pilha[-1][1] && ($abre || $fecha) && $i >= $pilha[-1][0]) {
    my $b = pop @pilha; push @blocos, [$b->[0], $i] if $i > $b->[0];
  }
}
my $d = quotemeta $dom; my $n = 0;
for my $b (sort { $b->[0] <=> $a->[0] } @blocos) {
  my ($s, $e) = @$b;
  my @blk = @L[$s .. $e];
  next unless grep { /^\s*server_name\b[^;#]*$d/ } @blk;
  my @novo;
  for my $k (0 .. $#blk) {
    my $ln = $blk[$k];
    next if $k > 0 && $k < $#blk && ($ln =~ /^\s*(client_max_body_size|proxy_read_timeout|proxy_send_timeout)\b/ || $ln =~ /ajuste WeCare/);
    push @novo, $ln;
    if ($k > 0 && $k < $#blk && $ln =~ /^(\s*)server_name\b[^;#]*$d[^;]*;\s*(#.*)?$/) {
      my $ind = length($1) ? $1 : "    ";
      push @novo, "${ind}# ajuste WeCare (portal do MCB): envios de até 64 MB e respostas de até 5 minutos\n",
                  "${ind}client_max_body_size 64m;\n", "${ind}proxy_read_timeout 300s;\n", "${ind}proxy_send_timeout 300s;\n";
      $n++;
    }
  }
  splice @L, $s, $e - $s + 1, @novo;
}
print @L;
exit($n ? 0 : 3);
PERL
for a in "${ARQS[@]}"; do
  perl "$BK/editar.pl" "$a" "$DOMINIO" > "$BK/novo" 2>"$BK/perl.txt"
  st=$?
  [ $st = 3 ] && continue   # arquivo cita o domínio fora de um bloco server: fica como está
  [ $st = 0 ] || { voltar; cat "$BK/perl.txt"; fim_erro "não consegui editar $a; voltei como estava."; }
  cat "$BK/novo" > "$a"
done
rm -f "$BK/novo" "$BK/perl.txt"
grep -q 'ajuste WeCare' "${ARQS[@]}" || { voltar; fim_erro "não achei onde colocar o ajuste; voltei como estava."; }

if ! $NGINX -t > "$BK/nginx-t.txt" 2>&1; then
  voltar; cat "$BK/nginx-t.txt"
  fim_erro "o nginx não aceitou o ajuste; voltei os arquivos como estavam (o site segue funcionando)."
fi
if ! $RECARREGAR; then
  voltar; $RECARREGAR
  fim_erro "não consegui recarregar o nginx; voltei os arquivos como estavam."
fi
echo "✓ nginx ajustado e recarregado. Linhas novas:"
grep -n -E 'client_max_body_size|proxy_read_timeout|proxy_send_timeout' "${ARQS[@]}" | sed 's/^/    /'

# conferência: um envio de 3 MB não pode mais ser recusado (413)
sleep 1
head -c 3145728 /dev/zero > "$BK/3mb"
code=$(curl -sk -o /dev/null -w '%{http_code}' --max-time 60 --resolve "$DOMINIO:$PORTA:127.0.0.1" \
  -X POST -H 'Content-Type: application/octet-stream' --data-binary @"$BK/3mb" "https://$DOMINIO:$PORTA/conferencia-limite-wecare")
rm -f "$BK/3mb"
if [ "$code" = 413 ]; then
  fim_erro "o ajuste foi gravado, mas o site ainda recusa envio de 3 MB. Pode haver outro limite em outro arquivo."
elif [ "$code" = 000 ]; then
  echo "(não consegui conferir pelo próprio servidor; o Pedro confere de fora)"
fi
echo
echo "✓ TUDO CERTO. Pode avisar o Pedro."
