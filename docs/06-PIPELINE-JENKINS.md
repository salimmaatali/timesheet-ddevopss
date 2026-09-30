# Étape 6 : créer le job Pipeline et lancer le build

**Objectif :** un job Jenkins lit le `Jenkinsfile` depuis GitHub et exécute toute la chaîne
automatiquement à chaque push.

Avant de commencer, vérifier : les conteneurs de l'étape 3 tournent (`cd ~/timesheet-project/devops && docker compose ps`)
et la configuration de l'étape 4 est faite.

---

## 6.1 Créer le job

1. Jenkins → **New Item**
2. **✋ À la main :** nom **`Prenom_NOM_CLASSE`** avec **vos** prénom, nom et classe (format demandé par le cours, ex. `Amine_BENASKER_5ARCTIC1`)
3. Type : **Pipeline** → **OK**

## 6.2 Configurer le job

**General**
- (optionnel) Description : `Pipeline CI/CD timesheet-devops`

**Build Triggers**
- ☑ **Poll SCM** → Schedule : `H/2 * * * *`
  (Jenkins regarde GitHub toutes les 2 minutes et lance un build s'il y a un nouveau commit.
  Le `Jenkinsfile` contient déjà ce réglage : il sera appliqué automatiquement après le 1er build.)

> **Pourquoi pas un webhook GitHub ?** Un webhook oblige GitHub (sur Internet) à contacter votre Jenkins,
> or celui-ci est sur `localhost`, inaccessible depuis Internet. Le *Poll SCM* fait l'inverse : c'est
> Jenkins qui interroge GitHub, donc ça marche sur un PC perso.

**Pipeline**

> **✋ À FAIRE À LA MAIN :** l'URL de **votre** dépôt GitHub (étape 5.2) et **votre** branche.

- Definition : **Pipeline script from SCM**
- SCM : **Git**
- Repository URL : `https://github.com/<votre_login_github>/timesheet-devops.git`
- Credentials : `- none -` si le dépôt est public, sinon `github-credentials`
- Branches to build → Branch Specifier : `*/main` (ou `*/prenom-nom` pour votre branche)
- Script Path : `Jenkinsfile`
- ☐ décocher *Lightweight checkout* si le build ne trouve pas le Jenkinsfile

**Save**.

## 6.3 Premier build

1. Cliquer **Build Now** (au 1er build, Jenkins découvre les paramètres du Jenkinsfile).
   Il utilise les valeurs que vous avez mises dans le `Jenkinsfile` à l'étape 5.3.
2. À partir du 2e build, le bouton devient **Build with Parameters**. Les valeurs sont pré-remplies
   avec celles du `Jenkinsfile` ; on peut les changer pour un build précis :

| Paramètre | Valeur |
|---|---|
| `DOCKERHUB_USER` | **votre** login Docker Hub, en minuscules (même que le credential `dockerhub-credentials`) |
| `PUSH_DOCKERHUB` | ☑ (décocher seulement si vous n'avez pas encore configuré Docker Hub) |
| `EMAIL_TO` | Mailpit : n'importe quelle adresse ; Gmail : votre vraie adresse |

> Si le stage DOCKER HUB échoue avec `denied`, c'est que `DOCKERHUB_USER` vaut encore
> `votre-compte-dockerhub` (étape 5.3 oubliée) ou qu'il est différent du login du credential (étape 4.3).

3. Suivre l'exécution : sur la page du job, le tableau **Stage View** montre chaque stage
   (vert = OK, rouge = échec). Cliquer sur le build `#N` → **Console Output** pour les logs complets.

Le 1er build est long (5 à 15 min) : Maven télécharge toutes les dépendances. Les suivants prennent 2 à 4 min.

## 6.4 Tester le déclenchement automatique (Travail à faire du chapitre Jenkins)

```bash
cd ~/timesheet-project
echo "# test trigger" >> README.md
git commit -am "Test du declenchement automatique"
git push
```
Dans les 2 minutes, un nouveau build démarre tout seul. Sur la page du build : *Started by an SCM change*.
Le lien **Git Polling Log** (menu du job) montre quand Jenkins a vérifié GitHub.

## 6.5 Ce que fait chaque stage du Jenkinsfile

| Stage | Commande | Explication |
|---|---|---|
| **GIT** | `checkout scm` | récupère le code de la branche configurée dans le job |
| **DATE SYSTEME** | `date` | affiche la date (Travail à faire du chapitre Jenkins) |
| **MVN CLEAN** | `mvn clean` | supprime le dossier `target/` du build précédent |
| **MVN COMPILE** | `mvn compile` | compile le code Java dans `target/classes` |
| **MOCKITO / JUNIT** | `mvn test` | lance les tests JUnit (sur H2) et Mockito ; JaCoCo mesure la couverture ; le rapport de tests apparaît dans *Test Result* |
| **SONARQUBE** | `mvn sonar:sonar` | envoie le code + la couverture à SonarQube (URL et token injectés par `withSonarQubeEnv`) |
| **NEXUS** | `mvn deploy -DskipTests -s ci/settings.xml` | construit le `.jar` et le dépose dans `maven-releases` ; les tests sont sautés car déjà faits |
| **DOCKER IMAGE** | `docker build -t <compte>/timesheet-devops:1.0.0 .` | construit l'image à partir du `Dockerfile` et du jar |
| **DOCKER HUB** | `docker login` + `docker push` | publie l'image sur Docker Hub (identifiants lus dans `dockerhub-credentials`) |
| **DOCKER COMPOSE** | `docker compose up -d` | démarre MySQL + l'application ; `-d` = en arrière-plan, pour ne pas bloquer le pipeline |
| **VERIFICATION APP** | `wget .../actuator/health` | attend que l'application réponde `{"status":"UP"}` |
| **post / always** | `emailext` | envoie le mail récapitulatif (succès ou échec) avec le log en pièce jointe |

**Pourquoi les tests sont avant SonarQube** (alors que le cours met Sonar avant) : SonarQube ne lance
pas les tests lui-même, il lit le rapport JaCoCo produit par `mvn test`. Si Sonar passe avant les
tests, la couverture affichée est de 0 % (c'est exactement ce que montre le cours, page 24).

**Pourquoi les mots de passe ne sont pas dans le Jenkinsfile :** le Jenkinsfile est public sur GitHub.
`withCredentials(...)` lit les secrets stockés dans Jenkins et les masque (`****`) dans les logs.

## 6.6 Bonus du cours : déclencher un build par URL

Configurer le job → *Build Triggers* → ☑ **Trigger builds remotely** → Authentication Token : `pipeline-token` → Save.
Ensuite, en étant connecté à Jenkins dans le navigateur :
```
http://localhost:8080/job/Prenom_NOM_CLASSE/buildWithParameters?token=pipeline-token
```
(`/build?token=...` pour un job sans paramètres.)

➡ Étape suivante : [07-VERIFIER-RESULTATS.md](07-VERIFIER-RESULTATS.md)
