# Étape 5 : mettre le projet sur GitHub

**Objectif :** le projet est sur **votre** dépôt GitHub, chaque membre a sa branche, et Jenkins
pourra récupérer le code à chaque push.

---

## 5.1 Configurer Git (une seule fois)

> **✋ À FAIRE À LA MAIN : votre identité Git** (elle apparaît sur chaque commit)

**Ubuntu**
```bash
git config --global user.name  "Prenom Nom"
git config --global user.email "prenom.nom@esprit.tn"
git config --global init.defaultBranch main
git config --global --list          # vérifier
```

## 5.2 Créer le dépôt sur GitHub

> **✋ À FAIRE À LA MAIN : dépôt GitHub** (avec le compte créé à l'étape 1.0)

1. https://github.com → **+** (en haut à droite) → **New repository**
2. Repository name : `timesheet-devops`
3. **Public** (plus simple pour Jenkins) ou Private (il faudra alors le credential `github-credentials`)
4. ⚠ **Ne cochez rien** (ni README, ni .gitignore, ni licence) : le projet a déjà ces fichiers
5. **Create repository** → copier l'URL `https://github.com/<vous>/timesheet-devops.git`

## 5.3 Mettre vos valeurs dans le Jenkinsfile (avant le premier push)

> **✋ À FAIRE À LA MAIN : votre login Docker Hub et votre e-mail dans le `Jenkinsfile`**
>
> Ouvrir le fichier :
> ```bash
> cd ~/timesheet-project
> nano Jenkinsfile          # ou : code Jenkinsfile (VS Code) / notepad depuis \\wsl$\Ubuntu\...
> ```
> Dans le bloc `parameters { ... }` en haut, remplacer les 2 valeurs `defaultValue` :
> ```groovy
> string(name: 'DOCKERHUB_USER', defaultValue: 'votre-compte-dockerhub', ...   // <- votre login Docker Hub (minuscules)
> ...
> string(name: 'EMAIL_TO', defaultValue: 'equipe@devops.local', ...           // <- votre e-mail (utile si option Gmail)
> ```
> Exemple : `defaultValue: 'amine2024'` et `defaultValue: 'amine@gmail.com'`.
> Enregistrer (`Ctrl+O`, `Entrée`, `Ctrl+X` dans nano).
>
> Vérifier :
> ```bash
> grep -n "defaultValue" Jenkinsfile
> ```
>
> Le login Docker Hub doit être **le même** que le *Username* du credential `dockerhub-credentials`
> (étape 4.3), sinon le `docker push` est refusé (`denied: requested access to the resource is denied`).

## 5.4 Premier push

> **✋ À FAIRE À LA MAIN : remplacer `<vous>` par votre login GitHub, et créer un token GitHub (voir sous le bloc)**

**Ubuntu**
```bash
cd ~/timesheet-project
git init                                   # crée le dépôt local
git add .                                  # prépare tous les fichiers (staging area)
git commit -m "Projet timesheet-devops : pipeline CI/CD complet"
git branch -M main
git remote add origin https://github.com/<vous>/timesheet-devops.git
git push -u origin main
```

GitHub demande un login : **Username** = votre login GitHub, **Password** = un *Personal Access Token*
(GitHub n'accepte plus le vrai mot de passe en ligne de commande) :
GitHub → avatar → **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**
→ *Generate new token (classic)* → cocher `repo` → *Generate* → copier `ghp_...`.

Pour ne pas le retaper à chaque fois :
```bash
git config --global credential.helper store    # mémorise le token après le prochain push
```

## 5.5 Travail en équipe (cours Git, « Travail à faire »)

1. Celui qui a créé le dépôt : GitHub → dépôt → **Settings** → **Collaborators** → **Add people**
   → ajouter chaque membre **et l'enseignant**.
2. Chaque membre récupère le projet **depuis GitHub** (pas depuis le zip) :
   ```bash
   cd ~
   git clone https://github.com/<proprietaire>/timesheet-devops.git
   cd timesheet-devops
   ```
3. Chacun crée **sa propre branche** et la pousse :
   ```bash
   git checkout -b prenom-nom          # crée la branche et bascule dessus
   git push -u origin prenom-nom
   ```
4. Chacun crée son job Jenkins (étape 6) sur **sa** branche.

Cycle de travail normal :
```bash
git status                           # ce qui a changé
git add .
git commit -m "Description du changement"
git push                             # -> Jenkins détecte le push et lance le pipeline
```

➡ Étape suivante : [06-PIPELINE-JENKINS.md](06-PIPELINE-JENKINS.md)
