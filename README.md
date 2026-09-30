# timesheet-devops : projet DevOps complet (ESPRIT)

Application **Spring Boot** (gestion d'utilisateurs, API REST + MySQL) intégrée dans une chaîne
**CI/CD** complète, comme demandé dans les chapitres du cours :

| Chapitre du cours | Où c'est dans le projet |
|---|---|
| 2 - Jenkins | `Jenkinsfile` (pipeline déclenché automatiquement à chaque push) |
| 3 - Docker | `Dockerfile` + stages `DOCKER IMAGE` / `DOCKER HUB` |
| 4 - Git | dépôt GitHub de l'équipe, une branche par membre |
| 5 - SonarQube | stage `SONARQUBE` + couverture JaCoCo |
| JUnit / Mockito | `src/test/...` (tests JUnit sur H2 + tests Mockito) |
| 7 - Nexus | stage `NEXUS` (`mvn deploy`) + `ci/settings.xml` |
| 8 - Docker Compose / Volume | `docker-compose.yml` (app + MySQL) + `devops/docker-compose.yml` |
| 9 - Surveillance continue | Prometheus + Grafana (`devops/prometheus/prometheus.yml`) |
| Mail récapitulatif | bloc `post` du `Jenkinsfile` + Mailpit |

---

## 1. Architecture

```
                        push                 poll (toutes les 2 min)
  Développeur ────────────────► GitHub ◄──────────────────────┐
                                                               │
 ┌──────────────── Windows 11 ── WSL 2 ── Ubuntu ──────────────┼──────────────────┐
 │                                                             │                  │
 │   Jenkins (service Ubuntu, port 8080) ──────────────────────┘                  │
 │     │  Java 17 + Maven + Git + Docker CLI                                      │
 │     │                                                                          │
 │     ├─ mvn test ──────────► rapports JUnit + couverture JaCoCo                 │
 │     ├─ mvn sonar:sonar ───► [SonarQube :9000]      conteneur                  │
 │     ├─ mvn deploy ────────► [Nexus :8081]          conteneur                  │
 │     ├─ docker build/push ─► Docker Hub (internet)                             │
 │     ├─ docker compose up ─► [timesheet-app :8082] + [MySQL :3307]  conteneurs │
 │     └─ mail ──────────────► [Mailpit :8025]        conteneur                  │
 │                                                                                │
 │   [Prometheus :9090] ── lit les métriques de Jenkins et de timesheet-app       │
 │   [Grafana :3000] ───── affiche les tableaux de bord à partir de Prometheus    │
 └────────────────────────────────────────────────────────────────────────────────┘
```

Tous les outils (sauf Jenkins) tournent dans des **conteneurs Docker** : rien à installer à la main
pour SonarQube, Nexus, Prometheus ou Grafana, une seule commande les démarre.

## 2. Ports utilisés

| Service | URL (navigateur Windows) | Identifiants par défaut |
|---|---|---|
| Jenkins | http://localhost:8080 | créés à l'installation |
| Nexus | http://localhost:8081 | `admin` / fichier `admin.password` |
| Application | http://localhost:8082/timesheet-devops/user/retrieve-all-users | - |
| SonarQube | http://localhost:9000 | `admin` / `admin` |
| Prometheus | http://localhost:9090 | - |
| Grafana | http://localhost:3000 | `admin` / `admin` |
| Mailpit (mails) | http://localhost:8025 | - |
| MySQL | localhost:**3307** | `root` / `root` |

## 3. Le parcours, dans l'ordre

Suivez les fichiers du dossier `docs/` **dans l'ordre** : chacun explique quoi faire, pourquoi,
et comment vérifier que ça a marché avant de passer au suivant.

| # | Fichier | Contenu | Durée |
|---|---|---|---|
| 1 | [docs/01-PREPARER-WSL.md](docs/01-PREPARER-WSL.md) | Vérifier WSL 2 / Ubuntu, mémoire, Docker, Java 17, Maven, Git | 30 min |
| 2 | [docs/02-INSTALLER-JENKINS.md](docs/02-INSTALLER-JENKINS.md) | Vérifier ou installer Jenkins, déverrouillage, accès Docker | 20 min |
| 3 | [docs/03-DEMARRER-OUTILS-DOCKER.md](docs/03-DEMARRER-OUTILS-DOCKER.md) | Lancer SonarQube, Nexus, Prometheus, Grafana, Mailpit + 1re connexion | 30 min |
| 4 | [docs/04-CONFIGURER-JENKINS.md](docs/04-CONFIGURER-JENKINS.md) | **Dashboard Jenkins** : plugins, Tools, Sonar, mail, credentials | 30 min |
| 5 | [docs/05-GITHUB.md](docs/05-GITHUB.md) | Mettre le projet sur GitHub, branches, collaborateurs | 15 min |
| 6 | [docs/06-PIPELINE-JENKINS.md](docs/06-PIPELINE-JENKINS.md) | Créer le job pipeline, lancer le 1er build, explication de chaque stage | 20 min |
| 7 | [docs/07-VERIFIER-RESULTATS.md](docs/07-VERIFIER-RESULTATS.md) | Vérifier Sonar, Nexus, Docker Hub, l'application, MySQL, le mail | 15 min |
| 8 | [docs/08-MONITORING-PROMETHEUS-GRAFANA.md](docs/08-MONITORING-PROMETHEUS-GRAFANA.md) | Surveiller Jenkins et l'application | 20 min |
| 9 | [docs/09-DEPANNAGE.md](docs/09-DEPANNAGE.md) | Erreurs fréquentes et solutions | - |
| 10 | [docs/10-VALIDATION-ET-QUESTIONS.md](docs/10-VALIDATION-ET-QUESTIONS.md) | Checklist pour la validation + questions du prof | - |

### ✋ Ce qu'il faut configurer à la main (valeurs personnelles)

Tout le reste est prêt. Ces points dépendent de **vous** : dans le guide, ils sont signalés par
un encadré **✋ À FAIRE À LA MAIN**, à l'étape exacte où ils se font.

| Quoi | Où dans le guide |
|---|---|
| Créer un compte GitHub et un compte Docker Hub | 1.0 |
| Mettre votre utilisateur Linux dans le groupe `docker` | 1.6 |
| Créer l'admin Jenkins | 2.3 |
| Mettre l'utilisateur `jenkins` dans le groupe `docker` | 2.4 |
| Mot de passe SonarQube + **token** `sqa_...` | 3.2 |
| Mot de passe Nexus + accès anonyme + *Allow redeploy* | 3.3 |
| Mot de passe Grafana | 3.4 |
| **Access Token Docker Hub** + credentials Jenkins (`sonar-token`, `nexus-credentials`, `dockerhub-credentials`) | 4.3 |
| **Mail** : Mailpit (rien à créer) ou Gmail (mot de passe d'application) | 4.4 |
| Identité Git (`user.name`, `user.email`) + dépôt GitHub | 5.1, 5.2 |
| **Votre login Docker Hub et votre e-mail dans le `Jenkinsfile`** | 5.3 |
| Token GitHub pour `git push` | 5.4 |
| Nom du job `Prenom_NOM_CLASSE` + URL de votre dépôt | 6.1, 6.2 |

> Démarrage rapide pour quelqu'un qui connaît déjà : `bash scripts/install-tools.sh`,
> `bash scripts/check-env.sh`, `cd devops && docker network create devops-net && docker compose up -d`,
> configurer Jenkins (doc 4), pousser sur GitHub, créer le job pipeline (doc 6).

## 4. Structure du projet

```
timesheet-project/
├── Jenkinsfile                  pipeline CI/CD (Groovy déclaratif)
├── Dockerfile                   image de l'application
├── docker-compose.yml           application + MySQL (lancé par Jenkins)
├── pom.xml                      Maven : dépendances, JaCoCo, Sonar, Nexus
├── ci/settings.xml              identifiants Nexus pour "mvn deploy" (lus depuis Jenkins)
├── devops/
│   ├── docker-compose.yml       SonarQube, Nexus, Prometheus, Grafana, Mailpit
│   └── prometheus/prometheus.yml  cibles surveillées par Prometheus
├── scripts/
│   ├── install-tools.sh         installe Java 17, Maven, Git dans Ubuntu
│   └── check-env.sh             vérifie que tout est prêt
├── docs/                        le guide pas à pas
└── src/
    ├── main/java/tn/esprit/spring/...   code de l'application
    ├── main/resources/application.properties
    ├── test/java/.../UserServiceImplTest.java       tests JUnit (Spring + H2)
    ├── test/java/.../UserServiceImplMockTest.java   tests Mockito
    └── test/resources/application.properties        config H2 des tests
```

## 5. Configuration minimale de la machine

- Windows 10/11 avec **WSL 2** et **Ubuntu** (22.04 ou 24.04)
- **16 Go de RAM** conseillés (8 Go donnés à WSL) : SonarQube + Nexus + Jenkins consomment beaucoup
- ~15 Go d'espace disque libre (images Docker)
- Un compte **GitHub** et un compte **Docker Hub** (gratuits)

## 6. Ce qui a été modifié par rapport au code source du cours

- `pom.xml` : Spring Boot 2.5.4 → **2.7.18**, Java 1.8 → **17** (les versions actuelles de Jenkins exigent Java 17),
  ajout de H2 (tests), JaCoCo (couverture), Actuator + Micrometer Prometheus (monitoring).
- `UserServiceImpl.retrieveAllUsers()` renvoyait `null` → renvoie maintenant la liste ; logs ajoutés (les `TODO` du cours).
- `User` : ajout de `getFirstName()/setFirstName()` (le prénom n'apparaissait pas dans le JSON).
- Tests : `UserServiceImplMock` renommé `UserServiceImplMockTest` (sinon Maven ne l'exécute pas),
  tests JUnit rendus indépendants de MySQL (base H2 en mémoire).
- `application.properties` : suppression du chemin de log `C:/logs/...` (inutilisable dans un conteneur Linux).
