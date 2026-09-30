# Étape 1 : préparer Windows, WSL 2 et Ubuntu

**Objectif :** avoir un Ubuntu (dans WSL 2) avec Java 17, Maven, Git et Docker qui fonctionnent.
Dans le cours, on utilise une VM Vagrant ; ici **WSL 2 remplace la VM** : c'est un vrai Linux
qui tourne dans Windows, sans VirtualBox.

> **Convention dans ce guide**
> - Bloc marqué **PowerShell** : à taper dans *Windows PowerShell* (menu Démarrer → « PowerShell »).
> - Bloc marqué **Ubuntu** : à taper dans le terminal Ubuntu (menu Démarrer → « Ubuntu », ou `wsl` dans PowerShell).
> - Une ligne qui commence par `#` est un commentaire : ne pas la taper.

> **✋ À FAIRE À LA MAIN** : les encadrés comme celui-ci signalent une valeur **personnelle** (compte,
> mot de passe, token…) que personne ne peut remplir à votre place. Le reste est du copier-coller.

---

## 1.0 Créer vos comptes (5 min)

> **✋ À FAIRE À LA MAIN : comptes en ligne**
> 1. **GitHub** : créer un compte gratuit sur https://github.com/signup (si vous n'en avez pas).
>    Notez votre **login GitHub**.
> 2. **Docker Hub** : créer un compte gratuit sur https://hub.docker.com/signup.
>    Notez votre **login Docker Hub** (tout en minuscules, ex. `amine2024`) : il servira de nom
>    pour votre image Docker (`<login>/timesheet-devops:1.0.0`).
>
> Les tokens (mots de passe pour Jenkins) seront créés plus tard, à l'étape où ils servent.

## 1.1 Vérifier que WSL 2 et Ubuntu sont installés

**PowerShell**
```powershell
wsl --status          # affiche la version par défaut (doit être 2)
wsl -l -v             # liste les distributions installées
```

Résultat attendu (exemple) :
```
  NAME              STATE           VERSION
* Ubuntu            Running         2
  docker-desktop    Running         2
```

- La colonne **VERSION doit être 2** pour Ubuntu.
  Si elle vaut 1 : `wsl --set-version Ubuntu 2`
- Si Ubuntu n'apparaît pas : `wsl --install -d Ubuntu`, redémarrer le PC, puis ouvrir « Ubuntu »
  et créer un nom d'utilisateur + mot de passe Linux (**retenez ce mot de passe** : c'est celui de `sudo`).
- Mettre WSL à jour : `wsl --update`

## 1.2 Donner assez de mémoire à WSL

SonarQube, Nexus et Jenkins ensemble ont besoin d'environ 6 Go. Par défaut WSL prend 50 % de la RAM.
Pour fixer la valeur, créer le fichier `C:\Users\<VOTRE_NOM>\.wslconfig` :

**PowerShell**
```powershell
notepad "$env:USERPROFILE\.wslconfig"
```
Contenu (pour un PC de 16 Go) :
```ini
[wsl2]
memory=8GB
swap=4GB
```
Puis redémarrer WSL pour appliquer :
```powershell
wsl --shutdown
```
(Si vous utilisez Docker Desktop, relancez-le ensuite.)

## 1.3 Vérifier que systemd est actif dans Ubuntu

Jenkins est un **service** : il est démarré par `systemctl`, qui a besoin de *systemd*.

**Ubuntu**
```bash
ps -p 1 -o comm=
```
- Affiche `systemd` → c'est bon.
- Affiche `init` → activer systemd :
  ```bash
  sudo nano /etc/wsl.conf
  ```
  Ajouter :
  ```ini
  [boot]
  systemd=true
  ```
  Enregistrer (`Ctrl+O`, `Entrée`, `Ctrl+X`), puis dans **PowerShell** : `wsl --shutdown`, et rouvrir Ubuntu.

Vérifier aussi la version d'Ubuntu et l'espace disque :
```bash
lsb_release -a        # Ubuntu 22.04 ou 24.04
df -h ~               # au moins 15 Go libres
free -h               # mémoire disponible (doit refléter .wslconfig)
```

## 1.4 Copier le projet dans Ubuntu

Le projet reçu en `.zip` est côté Windows. Il vaut mieux le copier **dans le disque Linux**
(beaucoup plus rapide pour Maven et Docker que de travailler dans `/mnt/c/...`).

1. Décompresser le zip dans Windows, par exemple dans `C:\Users\<VOTRE_NOM>\Downloads\timesheet-project`
2. **Ubuntu** :
```bash
# /mnt/c/ = le disque C: de Windows vu depuis Ubuntu
cp -r /mnt/c/Users/<VOTRE_NOM>/Downloads/timesheet-project ~/
cd ~/timesheet-project
ls
```
Vous devez voir `Jenkinsfile`, `Dockerfile`, `pom.xml`, `docs`, `devops`, `src`…

> Astuce : depuis l'Explorateur Windows, le dossier Linux est accessible à l'adresse `\\wsl$\Ubuntu\home\<user_linux>`.
> Et `explorer.exe .` dans Ubuntu ouvre le dossier courant dans l'Explorateur.

## 1.5 Installer Java 17, Maven et Git

**Pourquoi Java 17 et pas 11 comme dans le cours ?** Les versions actuelles de Jenkins refusent de
démarrer avec Java 11. On utilise donc Java 17 pour Jenkins *et* pour le projet.

Méthode automatique (fait tout ce qui suit) :
```bash
cd ~/timesheet-project
bash scripts/install-tools.sh
```

Méthode manuelle (pour comprendre chaque commande) :
```bash
sudo apt update                          # met à jour la liste des logiciels disponibles
sudo apt install -y openjdk-17-jdk       # Java 17 (compilateur + JVM)
sudo apt install -y maven                # Maven (build du projet)
sudo apt install -y git curl unzip       # Git + outils utiles

# Variables d'environnement (comme dans le cours, chapitre Jenkins)
echo 'JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"' | sudo tee -a /etc/environment
echo 'M2_HOME="/usr/share/maven"'                     | sudo tee -a /etc/environment
source /etc/environment
```

Vérifier :
```bash
java -version        # openjdk version "17.x"
mvn -v               # Apache Maven 3.x ... Java version: 17
git --version
echo $JAVA_HOME      # /usr/lib/jvm/java-17-openjdk-amd64
```

> Si `java -version` affiche 21 (Ubuntu 24.04 peut l'avoir déjà), ce n'est pas grave : Jenkins
> utilisera le JDK 17 déclaré dans *Tools* pour compiler le projet. Pour choisir la version par défaut :
> `sudo update-alternatives --config java`

> Le cours indique `M2_HOME="opt/apache-maven-3.6.3"` : ce chemin correspond à une installation manuelle.
> Avec `apt install maven`, Maven est dans **`/usr/share/maven`** : c'est ce chemin qu'on donnera à Jenkins.

## 1.6 Docker dans Ubuntu

Il faut que la commande `docker` fonctionne **dans Ubuntu**. Deux possibilités ; **n'en choisir qu'une**.

### Option A (recommandée si Docker Desktop est déjà installé sur Windows)

1. Ouvrir **Docker Desktop** → ⚙ *Settings* → *General* : cocher **Use the WSL 2 based engine**.
2. *Settings* → *Resources* → *WSL integration* : activer le bouton **Ubuntu** → *Apply & restart*.
3. Dans **Ubuntu** :
```bash
docker version            # doit afficher "Client" ET "Server"
docker compose version    # Docker Compose version v2.x
docker run hello-world    # télécharge et lance un conteneur de test
```

> Docker Desktop doit être **lancé** (icône de la baleine dans la barre des tâches) à chaque fois
> que vous travaillez sur le projet, sinon `docker` répond « Cannot connect to the Docker daemon ».

### Option B (sans Docker Desktop : Docker installé directement dans Ubuntu, comme dans le cours)

```bash
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker       # démarre Docker et l'active au démarrage
```

### Dans les deux cas : utiliser Docker sans `sudo`

> **✋ À FAIRE À LA MAIN : droits Docker de votre utilisateur Linux**
> ```bash
> sudo usermod -aG docker $USER    # ajoute VOTRE utilisateur Linux au groupe docker
> ```
> Fermer puis rouvrir le terminal Ubuntu (obligatoire), puis vérifier :
> ```bash
> groups          # la liste doit contenir "docker"
> docker ps       # pas d'erreur "permission denied"
> ```
> (L'utilisateur Linux `jenkins` aura besoin du même droit : ce sera fait à l'étape 2.4.)

## 1.7 Vérification finale

```bash
cd ~/timesheet-project
bash scripts/check-env.sh
```
Toutes les lignes doivent être `[OK]` ou `[--]`, sauf celles qui concernent Jenkins si vous ne l'avez
pas encore installé/configuré (étape suivante).

➡ Étape suivante : [02-INSTALLER-JENKINS.md](02-INSTALLER-JENKINS.md)
