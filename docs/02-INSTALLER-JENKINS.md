# Étape 2 : Jenkins dans Ubuntu (WSL 2)

**Objectif :** Jenkins tourne comme service dans Ubuntu, est accessible sur http://localhost:8080
depuis le navigateur Windows, et a le droit d'utiliser Docker.

---

## 2.1 Jenkins est déjà installé ? Vérifier

**Ubuntu**
```bash
sudo systemctl status jenkins      # doit afficher "active (running)" en vert ; q pour quitter
jenkins --version                  # version installée
```

- `active (running)` → passez directement au **2.4**.
- `inactive (dead)` → `sudo systemctl start jenkins` puis revérifier.
- `Unit jenkins.service could not be found` → Jenkins n'est pas installé : faire le **2.2**.
- Erreur `System has not been booted with systemd` → revoir l'étape 1.3.

## 2.2 Installer Jenkins (seulement s'il n'est pas installé)

Java 17 doit être installé avant (étape 1.5).

```bash
# 1. Télécharger la clé qui prouve que les paquets viennent bien de Jenkins
sudo mkdir -p /etc/apt/keyrings
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

# 2. Ajouter le dépôt Jenkins à la liste des sources de logiciels d'Ubuntu
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# 3. Mettre à jour la liste des paquets puis installer Jenkins
sudo apt update
sudo apt install -y jenkins

# 4. Démarrer Jenkins et l'activer au démarrage
sudo systemctl start jenkins
sudo systemctl enable jenkins
sudo systemctl status jenkins
```

> **Différence avec le cours :** la commande `apt-key` du cours n'existe plus dans les Ubuntu récents ;
> on utilise `/etc/apt/keyrings` à la place.
> Si `apt update` affiche `NO_PUBKEY` ou « not signed », la clé Jenkins a changé : copier les commandes
> à jour depuis https://www.jenkins.io/doc/book/installing/linux/#debianubuntu (section *Long Term Support*).

## 2.3 Premier démarrage (déverrouillage)

1. Dans le navigateur **Windows** : http://localhost:8080
   (WSL transmet automatiquement les ports d'Ubuntu vers Windows : pas besoin de l'IP comme avec Vagrant.)
2. Afficher le mot de passe initial :
   ```bash
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```
   Le copier-coller dans la page *Unlock Jenkins*.
3. Choisir **Install suggested plugins** et attendre (plusieurs minutes).
4. **✋ À la main :** créer l'utilisateur administrateur Jenkins (ex. `admin` / `jenkins`), **retenez-le**.
5. *Instance Configuration* : laisser `http://localhost:8080/` → *Save and Finish* → *Start using Jenkins*.

## 2.4 Donner à Jenkins le droit d'utiliser Docker

Le pipeline lance `docker build`, `docker push` et `docker compose` **en tant qu'utilisateur Linux `jenkins`**.

> **✋ À FAIRE À LA MAIN : utilisateur `jenkins` dans le groupe docker**
> ```bash
> sudo usermod -aG docker jenkins     # jenkins peut maintenant parler au démon Docker
> sudo systemctl restart jenkins      # obligatoire : les groupes sont lus au démarrage
> ```
> Vérifier :
> ```bash
> sudo -u jenkins docker ps           # doit lister les conteneurs, sans "permission denied"
> ```
> Sans cette étape, les stages DOCKER IMAGE / DOCKER HUB / DOCKER COMPOSE échouent.

Si ça affiche encore `permission denied while trying to connect to the Docker daemon socket` :
```bash
ls -l /var/run/docker.sock          # regarder le groupe propriétaire du fichier
sudo chmod 666 /var/run/docker.sock # solution du cours : ouvre le socket à tout le monde
```
> `chmod 666` est à refaire après chaque redémarrage de WSL/Docker Desktop. C'est acceptable pour un TP,
> pas pour un vrai serveur.

## 2.5 (Si besoin) changer le port de Jenkins

Si le port 8080 est déjà pris sur votre PC (Jenkins ne démarre pas, ou http://localhost:8080 affiche
autre chose), mettre Jenkins sur 8083 par exemple :

```bash
sudo systemctl edit jenkins
```
Dans l'éditeur qui s'ouvre, ajouter **entre les deux lignes de commentaires du haut** :
```ini
[Service]
Environment="JENKINS_PORT=8083"
```
Enregistrer, puis :
```bash
sudo systemctl daemon-reload
sudo systemctl restart jenkins
```
Jenkins est alors sur http://localhost:8083.

⚠ Si vous changez le port, remplacez aussi `8080` par le nouveau port dans
`devops/prometheus/prometheus.yml` (cible `jenkins`) et dans *Manage Jenkins → System → Jenkins URL*.

## 2.6 Commandes utiles au quotidien

```bash
sudo systemctl start jenkins      # démarrer
sudo systemctl stop jenkins       # arrêter
sudo systemctl restart jenkins    # redémarrer (après installation de plugins par ex.)
sudo journalctl -u jenkins -f     # voir les logs de Jenkins en direct (Ctrl+C pour quitter)
```

> Jenkins peut aussi être redémarré depuis le navigateur : http://localhost:8080/restart

➡ Étape suivante : [03-DEMARRER-OUTILS-DOCKER.md](03-DEMARRER-OUTILS-DOCKER.md)
