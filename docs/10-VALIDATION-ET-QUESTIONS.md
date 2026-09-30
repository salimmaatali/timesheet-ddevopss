# Validation du projet : checklist et questions du prof

La note du module = la **validation du projet final**. Préparez la démo avec cette liste.

---

## Avant la soutenance (10 min avant)

```bash
# Docker Desktop lancé (option A), puis dans Ubuntu :
sudo systemctl status jenkins                 # active (running)
cd ~/timesheet-project/devops && docker compose ps     # 5 conteneurs Up
cd ~/timesheet-project && docker compose ps            # app + mysql Up
bash scripts/check-env.sh
```
Ouvrir à l'avance les onglets : Jenkins, SonarQube, Nexus, Docker Hub, Prometheus/targets, Grafana, Mailpit.

## Checklist de la démo

- [ ] **Git** : dépôt GitHub de l'équipe, une branche par membre, enseignant invité
- [ ] **Jenkins** : job `Prenom_NOM_CLASSE` de type Pipeline, *Pipeline script from SCM*, `Jenkinsfile` dans le dépôt
- [ ] **Déclenchement automatique** : faire un petit commit + push devant le prof → le build démarre seul (≤ 2 min)
- [ ] **Stage View** entièrement vert, stages : GIT, DATE, CLEAN, COMPILE, MOCKITO/JUNIT, SONARQUBE, NEXUS, DOCKER IMAGE, DOCKER HUB, DOCKER COMPOSE
- [ ] **Tests** : *Test Result* avec les tests JUnit et Mockito
- [ ] **SonarQube** : projet `timesheet-devops` analysé, couverture > 0 %
- [ ] **Nexus** : `timesheet-devops-1.0.jar` dans `maven-releases`
- [ ] **Docker Hub** : image `<compte>/timesheet-devops:1.0.0`
- [ ] **Docker Compose** : `docker ps` montre `timesheet-app` + `timesheet-mysql` ; appel `curl` de l'API qui répond
- [ ] **Volume** : données MySQL conservées après `docker compose down` / `up`
- [ ] **Prometheus** : targets Jenkins + app **UP**
- [ ] **Grafana** : dashboard Jenkins (9964) + dashboard JVM de l'application (4701)
- [ ] **Mail** récapitulatif reçu dans Mailpit

## Questions fréquentes (et réponses)

**C'est quoi la différence entre CI, livraison continue et déploiement continu ?**
CI = compiler et tester automatiquement à chaque push. Livraison continue = déployer automatiquement
jusqu'à la pré-production, la mise en production reste manuelle. Déploiement continu = tout est
automatique, production comprise.

**Pourquoi un Jenkinsfile plutôt qu'un job Freestyle ?**
Le pipeline est du code (Groovy) versionné dans Git avec le projet : on voit son historique, on peut le
relire, le copier, et chaque étape apparaît séparément dans Stage View.

**Pourquoi le point `.` dans `docker build -t image:tag .` ?**
C'est le *contexte de build* : le dossier envoyé à Docker, qui contient le `Dockerfile` et
`target/timesheet-devops-1.0.jar`.

**Comment éviter que `docker compose up` bloque le pipeline ?**
Avec `-d` (*detached*) : les conteneurs tournent en arrière-plan et la commande rend la main tout de suite.

**Différence image / conteneur ?**
L'image est un modèle en lecture seule ; le conteneur est une instance de l'image en cours d'exécution.

**Différence VM / conteneur ?**
Une VM embarque son propre système d'exploitation (lourd, lent à démarrer, très isolé).
Un conteneur partage le noyau de l'hôte (léger, démarre en secondes, isolation au niveau du processus).

**À quoi sert un volume Docker ?**
À garder les données en dehors du conteneur : si on supprime le conteneur MySQL, les données restent
dans le volume `mysql_data`.

**Comment l'application trouve MySQL dans Docker Compose ?**
Par le **nom du service** `mysqldb` : Compose crée un réseau où chaque service est joignable par son nom
(`jdbc:mysql://mysqldb:3306/...`), et `depends_on` + `healthcheck` font démarrer l'app après MySQL.

**Release ou snapshot ?**
Release (`1.0`) : version stable, figée → `maven-releases`. Snapshot (`1.0-SNAPSHOT`) : version en
développement, redéployable → `maven-snapshots`.

**Pourquoi `-DskipTests` dans le stage Nexus ?**
Les tests ont déjà été exécutés dans le stage MOCKITO/JUNIT : inutile de les refaire.

**Tests dynamiques vs statiques ?**
Dynamiques = on exécute le code (JUnit, Mockito). Statiques = on analyse le code sans l'exécuter (SonarQube).

**À quoi sert Mockito ?**
À simuler (*mock*) les dépendances (ici `UserRepository`) pour tester `UserServiceImpl` seul, sans base
de données ni Spring : test plus rapide et vraiment unitaire.

**Pourquoi la couverture n'est-elle pas à 0 % comme dans le cours ?**
Parce que JaCoCo est intégré au `pom.xml` et que les tests tournent avant l'analyse Sonar.

**Bug vs Vulnerability vs Code Smell ?**
Bug = comportement incorrect possible. Vulnerability = faille de sécurité. Code smell = code difficile à
maintenir, mais qui fonctionne.

**Où sont les mots de passe ?**
Dans les **credentials** Jenkins (chiffrés), jamais dans le Jenkinsfile ; `withCredentials` les injecte
et les masque dans les logs.

**Prometheus vs Grafana ?**
Prometheus collecte et stocke les métriques (base de séries temporelles, langage PromQL).
Grafana ne stocke rien : il interroge Prometheus et affiche des tableaux de bord.
