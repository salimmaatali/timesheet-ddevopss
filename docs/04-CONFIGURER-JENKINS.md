# Étape 4 : configurer le dashboard Jenkins

**Objectif :** installer les plugins, déclarer Java et Maven, relier Jenkins à SonarQube, au serveur
mail, et enregistrer les mots de passe (credentials) utilisés par le `Jenkinsfile`.

Tout se fait dans le navigateur : http://localhost:8080 → menu de gauche **Manage Jenkins**
(*Administrer Jenkins* si Jenkins est en français).

> ⚠ Les **noms** en gras ci-dessous (`JDK17`, `M2_HOME`, `SonarQube`, `nexus-credentials`,
> `dockerhub-credentials`) sont utilisés tels quels dans le `Jenkinsfile`. Une faute de frappe ou une
> majuscule différente = pipeline en échec.

---

## 4.1 Plugins

**Manage Jenkins → Plugins → Available plugins**. Chercher et cocher chaque plugin, puis
**Install** (en haut à droite). En bas de la page de progression, cocher
*Restart Jenkins when installation is complete and no jobs are running*.

| Plugin | Pourquoi |
|---|---|
| **Git** | récupérer le code (normalement déjà installé : vérifier dans *Installed plugins*) |
| **Pipeline** | pipelines en Groovy (déjà installé avec les plugins suggérés) |
| **Pipeline: Stage View** | affiche les stages en tableau coloré sur la page du job |
| **Maven Integration** | demandé par le cours |
| **SonarQube Scanner** | fournit `withSonarQubeEnv(...)` utilisé dans le stage SONARQUBE |
| **Sonargraph Integration** | demandé par le cours (pas utilisé directement par le pipeline) |
| **Docker Pipeline** | intégration Docker dans les pipelines |
| **Email Extension** | fournit `emailext(...)` pour le mail récapitulatif |
| **Prometheus metrics** | expose les métriques de Jenkins sur `/prometheus` (chapitre 9) |
| **Timestamper** | heure devant chaque ligne de log (utilisé par `timestamps()`) |
| **Credentials Binding** | fournit `withCredentials(...)` (déjà installé normalement) |

Après le redémarrage, vérifier dans **Installed plugins** qu'ils sont tous présents.
Redémarrage manuel si besoin : `sudo systemctl restart jenkins` ou http://localhost:8080/restart

## 4.2 Tools : Java, Maven, Git

**Manage Jenkins → Tools**

**JDK installations → Add JDK**
- Name : **`JDK17`**
- ☐ décocher *Install automatically*
- JAVA_HOME : `/usr/lib/jvm/java-17-openjdk-amd64`

**Git installations** : laisser `Default` avec le chemin `git` (rien à configurer, comme dit le cours).

**Maven installations → Add Maven**
- Name : **`M2_HOME`**
- ☐ décocher *Install automatically*
- MAVEN_HOME : `/usr/share/maven`

Cliquer **Save**.

> Vérifier les chemins dans Ubuntu : `ls /usr/lib/jvm/` et `ls /usr/share/maven/bin/mvn`

## 4.3 Credentials (mots de passe stockés dans Jenkins)

> **✋ À FAIRE À LA MAIN : vos secrets personnels.** Préparez dans un bloc-notes :
> - le token SonarQube `sqa_...` (étape 3.2)
> - le mot de passe Nexus (étape 3.3)
> - votre login Docker Hub + un Access Token Docker Hub (créé juste en dessous)
> - si dépôt GitHub privé : votre login GitHub + un token GitHub (créé juste en dessous)

**Manage Jenkins → Credentials → System → Global credentials (unrestricted) → + Add Credentials**

Créer ces 3 credentials :

| Kind | Champs | ID (exactement) |
|---|---|---|
| **Secret text** | Secret = le token SonarQube `sqa_...` (étape 3.2) | **`sonar-token`** |
| **Username with password** | Username = `admin`, Password = mot de passe Nexus (ex. `nexus`) | **`nexus-credentials`** |
| **Username with password** | Username = votre compte Docker Hub, Password = un *Access Token* Docker Hub (voir ci-dessous) | **`dockerhub-credentials`** |

**✋ Créer l'Access Token Docker Hub** (plus sûr que le mot de passe du compte) :
1. Se connecter sur https://hub.docker.com avec le compte créé à l'étape 1.0.
2. Avatar → **Account settings** → **Personal access tokens** → **Generate new token**
3. Description `jenkins`, permissions **Read & Write** → *Generate* → copier le token `dckr_pat_...`
4. Dans Jenkins, credential `dockerhub-credentials` : Username = **votre login Docker Hub**
   (exactement le même que celui que vous mettrez dans le `Jenkinsfile` à l'étape 5.3), Password = ce token.

Vérifier le token depuis Ubuntu (facultatif) :
```bash
docker login -u <votre_login_dockerhub>     # coller le token comme mot de passe -> "Login Succeeded"
```

> Si votre dépôt GitHub est **privé**, ajouter aussi : *Username with password*, Username = votre login
> GitHub, Password = un *Personal Access Token* GitHub (GitHub → Settings → Developer settings →
> Personal access tokens → *Tokens (classic)* → scope `repo`), ID = `github-credentials`.

## 4.4 System : SonarQube, URL Jenkins, mail

**Manage Jenkins → System**, puis descendre section par section :

**Jenkins Location**
- Jenkins URL : `http://localhost:8080/`
- System Admin e-mail address : `jenkins@devops.local` (adresse d'expéditeur des mails ; votre
  adresse Gmail si vous choisissez l'option 2 plus bas)

**SonarQube servers**
- ☑ cocher *Environment variables : Enable injection of SonarQube server configuration as build environment variables*
- **Add SonarQube** :
  - Name : **`SonarQube`**
  - Server URL : `http://localhost:9000`
  - Server authentication token : choisir **`sonar-token`**

> **✋ À FAIRE À LA MAIN : le mail récapitulatif.** Choisir **une** des deux options :
> - **Option 1 : Mailpit (recommandé, rien à créer).** Les mails restent sur votre PC et se lisent sur http://localhost:8025.
> - **Option 2 : un vrai Gmail.** Les mails arrivent dans une vraie boîte, mais il faut un mot de passe d'application Google.

**Option 1 : Mailpit**

*Extended E-mail Notification* (plugin Email Extension) :
- SMTP server : `localhost`
- SMTP Port : `1025` (port SMTP de Mailpit)
- Cliquer *Advanced…* : laisser *Use SSL* / *Use TLS* **décochés**, pas de credentials
- Default Content Type : `HTML (text/html)`

*E-mail Notification* (mail de base de Jenkins, pratique pour tester) :
- SMTP server : `localhost`, *Advanced* → SMTP Port : `1025`
- ☑ *Test configuration by sending test e-mail* → adresse `test@devops.local` → **Test configuration**
- Ouvrir http://localhost:8025 : le mail de test doit être arrivé ✅

**Option 2 : Gmail**

1. ✋ Sur le compte Google : activer la **validation en 2 étapes**
   (https://myaccount.google.com/security), puis créer un **mot de passe d'application** :
   https://myaccount.google.com/apppasswords → nom `jenkins` → copier le code de 16 lettres.
2. *Jenkins Location* → System Admin e-mail address : **votre adresse Gmail**.
3. *Extended E-mail Notification* :
   - SMTP server : `smtp.gmail.com`, SMTP Port : `465`
   - *Advanced…* → Credentials → **Add** → *Username with password* :
     Username = votre adresse Gmail, Password = le code de 16 lettres, ID = `gmail-credentials`
   - ☑ **Use SSL**
   - Default Content Type : `HTML (text/html)`
4. *E-mail Notification* (pour le test) : SMTP server `smtp.gmail.com`, *Advanced* → ☑ *Use SMTP Authentication*
   (même adresse + code), ☑ *Use SSL*, SMTP Port `465` → **Test configuration** vers votre adresse.
5. Au lancement du pipeline, mettre votre adresse dans le paramètre `EMAIL_TO` (ou dans le `Jenkinsfile`, étape 5.3).

**Prometheus** (plugin Prometheus metrics)
- Laisser les valeurs par défaut (Path = `prometheus`). Vérifier que
  http://localhost:8080/prometheus/ affiche une longue liste de métriques texte.

Cliquer **Save**.

## 4.5 (Optionnel, TP du cours) premiers jobs Freestyle

Le chapitre Jenkins fait d'abord des jobs *Freestyle* pour découvrir l'interface :

1. **New Item** → nom `freestyle-1` → **Freestyle project** → OK
2. *Build Steps* → **Add build step** → **Execute shell** :
   ```bash
   echo "Bonjour, nous sommes le $(date)"
   mvn -version
   ```
3. *Save* → **Build Now** → cliquer sur le build `#1` → **Console Output**
4. Pour tester le déclenchement automatique : *Build Triggers* → **Build periodically** → `* * * * *`
   (toutes les minutes). ⚠ **Décochez-le ensuite**, sinon le job tourne indéfiniment.

➡ Étape suivante : [05-GITHUB.md](05-GITHUB.md)
