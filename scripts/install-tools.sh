#!/usr/bin/env bash
# Installe dans Ubuntu (WSL 2) les outils necessaires : Java 17, Maven, Git, curl
# et donne a l'utilisateur jenkins le droit d'utiliser Docker.
# Usage :  bash scripts/install-tools.sh
# (chaque commande est expliquee dans docs/01-PREPARER-WSL.md)
set -e

echo ">> Mise a jour de la liste des paquets"
sudo apt update

echo ">> Installation Java 17, Maven, Git, curl, unzip"
sudo apt install -y openjdk-17-jdk maven git curl unzip

echo ">> JAVA_HOME et M2_HOME dans /etc/environment"
grep -q '^JAVA_HOME=' /etc/environment || echo 'JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"' | sudo tee -a /etc/environment
grep -q '^M2_HOME=' /etc/environment   || echo 'M2_HOME="/usr/share/maven"' | sudo tee -a /etc/environment

if id jenkins >/dev/null 2>&1 && getent group docker >/dev/null; then
  echo ">> Ajout de l'utilisateur jenkins au groupe docker"
  sudo usermod -aG docker jenkins
  sudo systemctl restart jenkins || true
fi

echo
java -version
mvn -v | head -1
git --version
echo "Termine. Lancez maintenant : bash scripts/check-env.sh"
