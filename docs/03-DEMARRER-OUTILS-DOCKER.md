# Étape 3 : démarrer SonarQube, Nexus, Prometheus, Grafana et Mailpit

**Objectif :** les 5 outils tournent dans des conteneurs Docker, et vous avez fait leur première
connexion (mot de passe changé, token SonarQube créé, Nexus configuré).

Dans le cours, chaque outil est lancé avec un `docker run` séparé. Ici on utilise **Docker Compose**
(chapitre 8) : un seul fichier `devops/docker-compose.yml` décrit tous les conteneurs, et des
**volumes** gardent les données même si on supprime les conteneurs.

---

## 3.1 Lancer les conteneurs

**Ubuntu**
```bash
cd ~/timesheet-project/devops

# Réseau Docker partagé entre les outils et l'application (à faire une seule fois).
# Il permet à Prometheus de joindre le conteneur de l'application par son nom.
docker network create devops-net

# Télécharge les images (la 1re fois : ~2,5 Go, soyez patient) puis démarre tout en arrière-plan (-d)
docker compose up -d

# Etat des conteneurs : tous doivent être "Up" / "running"
docker compose ps
```

> Connexion lente ? Téléchargez les images une par une, puis relancez `docker compose up -d` :
> ```bash
> docker pull sonarqube:9.9-community
> docker pull sonatype/nexus3:3.70.1
> docker pull prom/prometheus:v2.53.0
> docker pull grafana/grafana:10.4.2
> docker pull axllent/mailpit:v1.20
> ```

**Temps de démarrage :** SonarQube ≈ 1 à 2 minutes, Nexus ≈ 2 à 4 minutes. Suivre les logs :
```bash
docker compose logs -f sonarqube    # attendre "SonarQube is operational"   (Ctrl+C pour quitter)
docker compose logs -f nexus        # attendre "Started Sonatype Nexus"
```

## 3.2 SonarQube : première connexion et token

> **✋ À FAIRE À LA MAIN :** nouveau mot de passe SonarQube + création du token `sqa_...`
> (à garder pour l'étape 4.3).

1. Ouvrir http://localhost:9000 → se connecter avec `admin` / `admin`.
2. SonarQube demande un nouveau mot de passe → par exemple `sonar` (comme dans le cours)…
   Certaines versions exigent un mot de passe plus long : utilisez alors par ex. `Sonar2024!Devops`.
3. Créer le **token** que Jenkins utilisera (le mot de passe ne doit pas être écrit dans le Jenkinsfile) :
   - En haut à droite, cliquer sur l'avatar **A** → **My Account** → onglet **Security**
   - *Generate Tokens* : Name = `jenkins`, Type = **Global Analysis Token**, Expires = *No expiration*
   - Cliquer **Generate**, puis **copier le token** (`sqa_...`) dans un bloc-notes :
     il ne sera **plus jamais affiché**.

## 3.3 Nexus : première connexion

> **✋ À FAIRE À LA MAIN :** nouveau mot de passe Nexus (à garder pour l'étape 4.3), accès anonyme,
> et *Allow redeploy* sur `maven-releases`.

1. Récupérer le mot de passe initial (généré dans le conteneur) :
   ```bash
   docker exec nexus cat /nexus-data/admin.password ; echo
   ```
2. Ouvrir http://localhost:8081 → **Sign in** (en haut à droite) → `admin` + le mot de passe affiché.
3. L'assistant démarre :
   - *New password* : par exemple `nexus` (comme dans le cours)
   - *Configure Anonymous Access* : **Enable anonymous access** (permet de télécharger sans mot de passe)
   - *Finish*
4. **Autoriser le redéploiement** (important) :
   notre version est `1.0` (une *release*). Par défaut Nexus refuse de recevoir 2 fois la même release,
   donc le **2e build** Jenkins échouerait avec `400 Repository does not allow updating assets`.
   - Cliquer sur l'engrenage ⚙ (Administration) → **Repository** → **Repositories** → **maven-releases**
   - *Deployment policy* : **Allow redeploy** → **Save**

> *Release vs Snapshot (question classique du prof)* : une release (`1.0`) est une version stable et
> figée ; une snapshot (`1.0-SNAPSHOT`) est une version en cours de développement, qui peut être
> redéployée autant de fois qu'on veut dans le dépôt `maven-snapshots`.

## 3.4 Grafana : première connexion

1. Ouvrir http://localhost:3000 → `admin` / `admin`
2. **✋ À la main :** choisir un nouveau mot de passe, par exemple `grafana`.
(La configuration de Grafana se fait à l'étape 8.)

## 3.5 Prometheus et Mailpit

- http://localhost:9090 → interface Prometheus. *Status → Targets* : la cible `prometheus` est **UP** ;
  `jenkins` et `timesheet-app` seront **DOWN** pour l'instant (normal, on les configure plus tard).
- http://localhost:8025 → boîte de réception Mailpit (vide pour l'instant). Mailpit est un faux
  serveur de mails : Jenkins lui envoie les mails, et on les lit ici, sans configurer Gmail.

## 3.6 Arrêter / redémarrer les outils

```bash
cd ~/timesheet-project/devops
docker compose stop        # arrête les conteneurs (les données restent)
docker compose start       # les redémarre
docker compose down        # supprime les conteneurs (les VOLUMES, donc les données, restent)
docker compose down -v     # ⚠ supprime aussi les volumes : tout est à reconfigurer
```

> Le cours rappelle : ne pas refaire `docker run` pour relancer un conteneur existant (ça en crée un
> nouveau, vide). Avec Compose, `docker compose up -d` est sans risque : il réutilise les conteneurs
> et les volumes existants.

Après un redémarrage du PC : lancer Docker Desktop (option A), puis :
```bash
cd ~/timesheet-project/devops && docker compose start
```
(Ils redémarrent aussi tout seuls grâce à `restart: unless-stopped`.)

➡ Étape suivante : [04-CONFIGURER-JENKINS.md](04-CONFIGURER-JENKINS.md)
