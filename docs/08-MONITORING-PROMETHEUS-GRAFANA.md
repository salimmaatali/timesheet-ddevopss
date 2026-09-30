# Étape 8 : surveillance continue avec Prometheus et Grafana

**Objectif (Travail à faire du chapitre 9) :** Prometheus collecte les métriques de **Jenkins** et de
l'**application Spring Boot**, et Grafana les affiche dans des tableaux de bord.

```
 Jenkins :8080/prometheus/  ─┐
                             ├──►  Prometheus :9090  ──►  Grafana :3000
 timesheet-app :8082/...     ─┘    (collecte toutes       (graphiques)
   /actuator/prometheus            les 15 s)
```

---

## 8.1 Vérifier que les métriques sont exposées

- **Jenkins** (plugin *Prometheus metrics*, installé à l'étape 4) :
  http://localhost:8080/prometheus/ → une longue page de texte (`jenkins_...`, `default_jenkins_...`).
- **Application** (Actuator + Micrometer, ajoutés dans `pom.xml`) :
  http://localhost:8082/timesheet-devops/actuator/prometheus → métriques `jvm_...`, `http_server_requests_...`

## 8.2 Configuration de Prometheus

Elle est déjà écrite dans `devops/prometheus/prometheus.yml` (le cours la fait éditer à la main dans le
conteneur ; ici le fichier est dans le projet et monté dans le conteneur) :

```yaml
scrape_configs:
  - job_name: 'jenkins'
    metrics_path: '/prometheus/'
    static_configs:
      - targets: ['host.docker.internal:8080']   # Jenkins tourne dans Ubuntu, hors Docker
  - job_name: 'timesheet-app'
    metrics_path: '/timesheet-devops/actuator/prometheus'
    static_configs:
      - targets: ['timesheet-app:8082']          # nom du conteneur, sur le réseau devops-net
```

Vérifier la configuration vue par le conteneur (commande du cours) :
```bash
docker exec prometheus cat /etc/prometheus/prometheus.yml
```

Après une modification du fichier, redémarrer Prometheus :
```bash
cd ~/timesheet-project/devops && docker compose restart prometheus
```

Ouvrir http://localhost:9090/targets : les 3 cibles `prometheus`, `jenkins`, `timesheet-app` doivent être **UP**.

**Si `jenkins` est DOWN** (erreur *connection refused* ou *no such host*) :
```bash
hostname -I            # dans Ubuntu : première adresse, ex. 172.28.150.12
```
Remplacer `host.docker.internal:8080` par `172.28.150.12:8080` dans `prometheus.yml`, puis
`docker compose restart prometheus`. (Cette IP peut changer après un redémarrage de Windows.)

**Si `timesheet-app` est DOWN** : l'application n'est pas lancée → lancer le pipeline (stage DOCKER COMPOSE).

Petit test de requête PromQL : dans http://localhost:9090 → onglet *Graph*, taper
`jvm_memory_used_bytes` ou `jenkins_executor_count_value` → **Execute**.

## 8.3 Grafana : ajouter la source de données Prometheus

1. http://localhost:3000 (admin / mot de passe choisi à l'étape 3)
2. Menu ☰ → **Connections** → **Data sources** → **Add data source** → **Prometheus**
3. Name : `Prometheus`
4. Prometheus server URL : **`http://prometheus:9090`**
   (Grafana et Prometheus sont sur le même réseau Docker : le **nom du conteneur** suffit, pas besoin
   de chercher son adresse IP comme dans le cours)
5. En bas : **Save & test** → message vert *Successfully queried the Prometheus API* ✅

## 8.4 Importer le tableau de bord Jenkins (ID 9964)

1. Menu ☰ → **Dashboards** → **New** → **Import**
2. *Import via grafana.com* : taper **`9964`** → **Load**
3. Choisir la source de données **Prometheus** → **Import**
4. Le tableau *Jenkins: Performance and Health Overview* s'affiche (nombre de jobs, builds, file
   d'attente, mémoire JVM de Jenkins…). Lancez 2 ou 3 builds pour voir les courbes bouger.
5. Enregistrer : icône 💾 (*Save dashboard*) en haut.

## 8.5 Importer le tableau de bord de l'application Spring Boot (ID 4701)

Même procédure avec l'ID **`4701`** (*JVM (Micrometer)*) → source **Prometheus** → **Import**.
En haut du tableau, choisir `application = timesheet-devops`.
On y voit la mémoire, les threads, le CPU, le garbage collector et les requêtes HTTP de l'application.

Générer un peu de trafic pour voir les courbes :
```bash
for i in $(seq 1 50); do curl -s http://localhost:8082/timesheet-devops/user/retrieve-all-users > /dev/null; done
```

## 8.6 Résultat attendu pour la validation

- Prometheus → Targets : 3 cibles **UP**
- Grafana : dashboard **Jenkins (9964)** + dashboard **Spring Boot / JVM (4701)** avec des données

➡ En cas de problème : [09-DEPANNAGE.md](09-DEPANNAGE.md) · Avant la soutenance : [10-VALIDATION-ET-QUESTIONS.md](10-VALIDATION-ET-QUESTIONS.md)
