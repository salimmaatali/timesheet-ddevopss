# Étape 7 : vérifier les résultats du pipeline

Après un build **vert**, chaque outil doit montrer le résultat de son stage.

---

## 7.1 Tests (Jenkins)

Page du build → **Test Result** : 11 tests, 0 échec
(`UserServiceImplTest` : 5 tests JUnit ; `UserServiceImplMockTest` : 6 tests Mockito).

## 7.2 SonarQube

http://localhost:9000 → **Projects** → **timesheet-devops**

| Indicateur | Signification |
|---|---|
| **Bugs** | défaut qui peut provoquer un comportement incorrect (ex. NullPointerException) |
| **Vulnerabilities** | faiblesse de sécurité |
| **Security Hotspots** | code sensible à relire à la main |
| **Code Smells** | mauvaise pratique (imports inutiles, commentaires en trop…), pas un bug |
| **Coverage** | % du code exécuté par les tests (vient de JaCoCo : > 0 % ici) |
| **Duplications** | % de code copié-collé |
| **Quality Gate** | Passed / Failed selon les seuils de qualité |

## 7.3 Nexus

http://localhost:8081 → **Browse** → **maven-releases** →
`tn/esprit/spring/services/timesheet-devops/1.0/timesheet-devops-1.0.jar` ✅

## 7.4 Docker Hub et images locales

- https://hub.docker.com → **Repositories** → `timesheet-devops` avec le tag `1.0.0`
- Dans Ubuntu :
  ```bash
  docker images | grep timesheet-devops
  ```

## 7.5 L'application et MySQL

```bash
docker ps                                   # timesheet-app et timesheet-mysql sont "Up"
docker logs -f timesheet-app                # logs Spring Boot (Ctrl+C pour quitter)
```

Tester l'API REST (depuis Ubuntu, ou coller les URL GET dans le navigateur Windows) :
```bash
# Ajouter un utilisateur
curl -X POST http://localhost:8082/timesheet-devops/user/add-user \
     -H "Content-Type: application/json" \
     -d '{"firstName":"Amine","lastName":"Ben","dateNaissance":"2000-01-15","role":"INGENIEUR"}'

# Lister les utilisateurs
curl http://localhost:8082/timesheet-devops/user/retrieve-all-users

# Un utilisateur par id
curl http://localhost:8082/timesheet-devops/user/retrieve-user/1

# Modifier
curl -X PUT http://localhost:8082/timesheet-devops/user/modify-user \
     -H "Content-Type: application/json" \
     -d '{"id":1,"firstName":"Amine","lastName":"Modifie","dateNaissance":"2000-01-15","role":"TECHNICIEN"}'

# Supprimer
curl -X DELETE http://localhost:8082/timesheet-devops/user/remove-user/1

# Santé de l'application (utilisé par Jenkins)
curl http://localhost:8082/timesheet-devops/actuator/health
```

Voir les données directement dans MySQL :
```bash
# (Spring Boot crée la table en minuscules : t_user)
docker exec -it timesheet-mysql mysql -uroot -proot timesheet_db -e "SELECT * FROM t_user;"
```

**Docker Volume (chapitre 8)** : les données MySQL sont dans le volume `timesheet_mysql_data`.
Preuve qu'elles survivent à la suppression du conteneur :
```bash
cd ~/timesheet-project
docker compose down            # supprime les conteneurs
docker volume ls | grep mysql  # le volume existe toujours
# recrée les conteneurs ; hors Jenkins il faut indiquer l'image à utiliser :
IMAGE_NAME=<compte>/timesheet-devops:1.0.0 docker compose up -d
sleep 40                       # le temps que Spring Boot démarre
curl http://localhost:8082/timesheet-devops/user/retrieve-all-users   # les utilisateurs sont toujours là
```

## 7.6 Mail récapitulatif

http://localhost:8025 → un mail `[Jenkins] Prenom_NOM_CLASSE #N : SUCCESS` avec le log en pièce jointe.

➡ Étape suivante : [08-MONITORING-PROMETHEUS-GRAFANA.md](08-MONITORING-PROMETHEUS-GRAFANA.md)
