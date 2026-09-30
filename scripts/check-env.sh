#!/usr/bin/env bash
# Verifie que l'environnement Ubuntu (WSL 2) est pret pour le projet.
# Usage (dans Ubuntu) :  bash scripts/check-env.sh
# Chaque ligne affiche [OK], [!!] (a corriger) ou [--] (information).

ok()   { printf '  \033[32m[OK]\033[0m %s\n' "$1"; }
bad()  { printf '  \033[31m[!!]\033[0m %s\n' "$1"; FAILS=$((FAILS+1)); }
info() { printf '  \033[33m[--]\033[0m %s\n' "$1"; }
FAILS=0

echo "== Systeme"
if grep -qi microsoft /proc/version; then ok "WSL detecte : $(uname -r)"; else info "Pas sous WSL (machine Linux classique ?)"; fi
. /etc/os-release && ok "Distribution : $PRETTY_NAME"
if [ "$(ps -p 1 -o comm=)" = "systemd" ]; then ok "systemd actif (necessaire pour 'systemctl start jenkins')"
else bad "systemd inactif -> voir docs/01-PREPARER-WSL.md (fichier /etc/wsl.conf)"; fi
MEM_GB=$(awk '/MemTotal/ {printf "%.1f", $2/1024/1024}' /proc/meminfo)
info "Memoire vue par WSL : ${MEM_GB} Go (recommande : 8 Go ou plus)"

echo "== Outils"
if command -v java >/dev/null; then
  JV=$(java -version 2>&1 | head -1); ok "Java : $JV"
  echo "$JV" | grep -Eq '"(17|21)' || bad "Jenkins et ce projet demandent Java 17 (ou 21)"
else bad "Java absent -> sudo apt install -y openjdk-17-jdk"; fi
if [ -d /usr/lib/jvm/java-17-openjdk-amd64 ]; then ok "JDK 17 : /usr/lib/jvm/java-17-openjdk-amd64 (chemin a mettre dans Jenkins > Tools)"
else bad "Dossier /usr/lib/jvm/java-17-openjdk-amd64 absent"; fi
if command -v mvn >/dev/null; then ok "Maven : $(mvn -v 2>/dev/null | head -1)"; else bad "Maven absent -> sudo apt install -y maven"; fi
if command -v git >/dev/null; then ok "Git : $(git --version)"; else bad "Git absent -> sudo apt install -y git"; fi
if command -v curl >/dev/null; then ok "curl present"; else bad "curl absent -> sudo apt install -y curl"; fi

echo "== Docker"
if command -v docker >/dev/null; then
  ok "Docker CLI : $(docker --version)"
  if docker info >/dev/null 2>&1; then ok "Docker repond pour l'utilisateur $(whoami)"
  else bad "Docker ne repond pas (Docker Desktop lance ? integration WSL activee ? groupe docker ?)"; fi
  if docker compose version >/dev/null 2>&1; then ok "$(docker compose version)"; else bad "docker compose (v2) absent"; fi
else bad "Docker absent -> voir docs/01-PREPARER-WSL.md"; fi

echo "== Jenkins"
if systemctl list-unit-files 2>/dev/null | grep -q '^jenkins'; then
  if systemctl is-active --quiet jenkins; then ok "Service jenkins actif"; else bad "Service jenkins arrete -> sudo systemctl start jenkins"; fi
  PORT=$(systemctl show jenkins -p Environment 2>/dev/null | grep -o 'JENKINS_PORT=[0-9]*' | cut -d= -f2)
  info "Port Jenkins : ${PORT:-8080}"
  if id jenkins >/dev/null 2>&1; then
    if sudo -n -u jenkins docker info >/dev/null 2>&1; then ok "L'utilisateur jenkins peut utiliser Docker"
    elif id -nG jenkins | grep -qw docker; then info "jenkins est dans le groupe docker (redemarrer Jenkins si le pipeline echoue)"
    else bad "jenkins n'a pas acces a Docker -> sudo usermod -aG docker jenkins && sudo systemctl restart jenkins"; fi
  fi
else bad "Jenkins n'est pas installe -> voir docs/02-INSTALLER-JENKINS.md"; fi

echo "== Ports (qui ecoute ?)"
for p in 8080 8081 8082 9000 9090 3000 3307 8025; do
  if ss -ltn 2>/dev/null | awk '{print $4}' | grep -Eq "[:.]$p$"; then info "port $p : utilise"; else info "port $p : libre"; fi
done

echo
if [ "$FAILS" -eq 0 ]; then echo "Tout est pret."; else echo "$FAILS point(s) a corriger (lignes [!!])."; fi
