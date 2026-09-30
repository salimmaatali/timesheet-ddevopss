# Dépannage : erreurs fréquentes

Réflexe n°1 : ouvrir le build en échec → **Console Output**, descendre jusqu'à la **première** ligne
`ERROR` / `FAILED`. Le nom du stage rouge dans *Stage View* indique quel outil vérifier.

Réflexe n°2 : `bash scripts/check-env.sh`

---

## WSL / Docker

| Symptôme | Cause | Solution |
|---|---|---|
| `Cannot connect to the Docker daemon` | Docker Desktop fermé (option A) ou service arrêté (option B) | lancer Docker Desktop / `sudo systemctl start docker` |
| `docker: command not found` dans Ubuntu | intégration WSL non activée | Docker Desktop → Settings → Resources → WSL integration → Ubuntu |
| `permission denied ... docker.sock` dans le **pipeline** | l'utilisateur `jenkins` n'a pas accès à Docker | `sudo usermod -aG docker jenkins && sudo systemctl restart jenkins` ; sinon `sudo chmod 666 /var/run/docker.sock` |
| `System has not been booted with systemd` | systemd désactivé dans WSL | étape 1.3 (`/etc/wsl.conf`) |
| PC très lent, conteneurs qui s'arrêtent seuls (`Exited (137)`) | manque de mémoire | `.wslconfig` (étape 1.2) ; arrêter ce qui ne sert pas : `docker compose stop grafana prometheus` |
| `unexpected EOF` / `TLS handshake timeout` pendant un `docker pull` | connexion instable | relancer ; télécharger les images **une par une** (étape 3.1) |
| `network devops-net declared as external, but could not be found` | réseau jamais créé | `docker network create devops-net` |

## Jenkins

| Symptôme | Cause | Solution |
|---|---|---|
| `Tool type "jdk" does not have an install of "JDK17" configured` | nom différent dans *Tools* | Manage Jenkins → Tools : nom exact `JDK17` (et `M2_HOME` pour Maven) |
| `No such DSL method 'withSonarQubeEnv'` / `'emailext'` | plugin manquant | installer *SonarQube Scanner* / *Email Extension*, redémarrer Jenkins |
| `Invalid option type "timestamps"` | plugin Timestamper absent | installer *Timestamper* |
| `ERROR: Could not find credentials entry with ID 'nexus-credentials'` | credential absent ou ID différent | étape 4.3, vérifier l'ID exact |
| `couldn't find remote ref refs/heads/main` | la branche n'existe pas sur GitHub | vérifier *Branch Specifier* (`*/main` ou `*/master` ou `*/prenom-nom`) |
| `Authentication failed` lors du checkout | dépôt privé sans credential | credential `github-credentials` avec un token GitHub (étape 4.3) |
| Le build ne se lance pas après un push | Poll SCM pas encore actif | lancer 1 build à la main (le trigger est lu dans le Jenkinsfile au 1er build) ; voir *Git Polling Log* |
| Jenkins ne démarre pas, `Address already in use` | port 8080 déjà pris | changer de port (étape 2.5) ; voir qui l'utilise : `sudo ss -ltnp | grep 8080` |
| `Running with Java 11... not supported` | Jenkins lancé avec Java 11 | `sudo apt install openjdk-17-jdk` puis `sudo update-alternatives --config java` → 17 |

## Maven / tests

| Symptôme | Cause | Solution |
|---|---|---|
| `invalid target release: 17` | Maven utilise un vieux JDK | vérifier `JDK17` dans Tools ; en local : `export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64` |
| Tests en échec avec `Communications link failure` (MySQL) | le fichier `src/test/resources/application.properties` manque | il doit exister (base H2 pour les tests) |
| Téléchargements Maven très lents au 1er build | normal : cache vide | patienter ; les builds suivants utilisent `~/.m2` de jenkins |

## SonarQube

| Symptôme | Cause | Solution |
|---|---|---|
| `Not authorized. Please check the user token` | token faux/expiré | recréer le token (étape 3.2), mettre à jour le credential `sonar-token` |
| `SonarQube server [http://localhost:9000] can not be reached` | conteneur arrêté ou encore en démarrage | `docker compose ps` ; `docker compose logs sonarqube` ; attendre *SonarQube is operational* |
| Conteneur sonarqube qui redémarre en boucle, `max virtual memory areas vm.max_map_count` | noyau WSL | déjà contourné par `SONAR_ES_BOOTSTRAP_CHECKS_DISABLE` ; sinon dans PowerShell : `wsl -d docker-desktop sysctl -w vm.max_map_count=262144` (option A) ou `sudo sysctl -w vm.max_map_count=262144` dans Ubuntu (option B) |
| Coverage = 0 % | tests non exécutés avant Sonar | garder l'ordre du Jenkinsfile (MOCKITO avant SONARQUBE) |

## Nexus

| Symptôme | Cause | Solution |
|---|---|---|
| `401 Unauthorized` | mauvais mot de passe dans `nexus-credentials` | le mettre à jour (étape 4.3) |
| `400 Repository does not allow updating assets: maven-releases` | 2e déploiement de la version 1.0 | Nexus → maven-releases → *Deployment policy* = **Allow redeploy** (étape 3.3) |
| `Connection refused localhost:8081` | Nexus pas démarré ou encore en démarrage (≈ 3 min) | `docker compose logs -f nexus` |

## Docker Hub / Docker Compose / application

| Symptôme | Cause | Solution |
|---|---|---|
| `denied: requested access to the resource is denied` au push | `DOCKERHUB_USER` ≠ compte du token | *Build with Parameters* avec votre vrai login ; token avec droits *Read & Write* |
| `invalid reference format: repository name must be lowercase` | majuscules dans `DOCKERHUB_USER` | tout en minuscules |
| `Bind for 0.0.0.0:3307 failed: port is already allocated` | port déjà utilisé | changer `"3307:3306"` dans `docker-compose.yml` |
| Stage VERIFICATION APP en échec | l'app ne démarre pas | lire la fin du log du stage (il affiche `docker logs timesheet-app`) ; souvent MySQL pas prêt → relancer le build |
| `pull access denied for timesheet-devops` en lançant `docker compose up` à la main | variable `IMAGE_NAME` absente | `IMAGE_NAME=<compte>/timesheet-devops:1.0.0 docker compose up -d` |

## Repartir de zéro (en dernier recours)

```bash
# Application
cd ~/timesheet-project && docker compose down -v
# Outils (⚠ perd la config SonarQube/Nexus/Grafana : refaire l'étape 3)
cd devops && docker compose down -v && docker compose up -d
```
