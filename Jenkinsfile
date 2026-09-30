// =====================================================================
//  Pipeline CI/CD - timesheet-devops
//  GIT -> DATE -> MVN CLEAN/COMPILE -> MOCKITO/JUNIT -> SONARQUBE -> NEXUS
//      -> DOCKER IMAGE -> DOCKER HUB -> DOCKER COMPOSE -> VERIFICATION -> MAIL
//
//  Prerequis dans Jenkins (voir docs/04-CONFIGURER-JENKINS.md) :
//   - Tools        : JDK nomme "JDK17", Maven nomme "M2_HOME"
//   - Serveur Sonar: nomme "SonarQube" (URL http://localhost:9000 + token)
//   - Credentials  : "nexus-credentials" et "dockerhub-credentials"
// =====================================================================
pipeline {
    agent any

    tools {
        jdk 'JDK17'
        maven 'M2_HOME'
    }

    // ✋ A MODIFIER A LA MAIN avant le 1er push : votre login Docker Hub et votre e-mail
    //   (voir docs/05-GITHUB.md, etape 5.3)
    parameters {
        string(name: 'DOCKERHUB_USER', defaultValue: 'salim145',
               description: 'Votre nom d\'utilisateur Docker Hub (en minuscules)')
        booleanParam(name: 'PUSH_DOCKERHUB', defaultValue: true,
                     description: 'Envoyer l\'image sur Docker Hub (necessite le credential dockerhub-credentials)')
        string(name: 'EMAIL_TO', defaultValue: 'equipe@devops.local',
               description: 'Destinataire du mail recapitulatif (visible dans Mailpit : http://localhost:8025)')
    }

    environment {
    IMAGE_NAME = "${params.DOCKERHUB_USER}/timesheet-devops:1.5"
}

    triggers {
        // Verifie GitHub toutes les ~2 minutes : un nouveau push lance le pipeline automatiquement
        pollSCM('H/2 * * * *')
    }

    options {
        skipDefaultCheckout()      // le checkout est fait dans le stage GIT (comme dans le cours)
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {

        stage('GIT') {
            steps {
                echo 'Recuperation du code depuis GitHub'
                checkout scm
                sh 'git log -1 --oneline'
            }
        }

        stage('DATE SYSTEME') {
            steps {
                sh 'date'
            }
        }

        stage('MVN CLEAN') {
            steps {
                sh 'mvn -B clean'
            }
        }

        stage('MVN COMPILE') {
            steps {
                sh 'mvn -B compile'
            }
        }

        stage('MOCKITO / JUNIT') {
            steps {
                // Lance les tests + genere le rapport de couverture JaCoCo (target/site/jacoco)
                sh 'mvn -B test'
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: 'target/surefire-reports/*.xml'
                }
            }
        }

        stage('SONARQUBE') {
            steps {
                // "SonarQube" = nom du serveur declare dans Manage Jenkins > System
                withSonarQubeEnv('SonarQube') {
                    sh 'mvn -B sonar:sonar'
                }
            }
        }

        stage('NEXUS') {
            steps {
                // Depose timesheet-devops-1.5.jar dans maven-releases (tests deja faits -> skip)
                withCredentials([usernamePassword(credentialsId: 'nexus-credentials',
                                                  usernameVariable: 'NEXUS_USER',
                                                  passwordVariable: 'NEXUS_PASSWORD')]) {
                    sh 'mvn -B deploy -DskipTests -s ci/settings.xml'
                }
            }
        }

        stage('DOCKER IMAGE') {
            steps {
                // Le "." = contexte de build : le dossier courant, qui contient le Dockerfile et target/
                sh 'docker build -t "$IMAGE_NAME" .'
                sh 'docker images | grep timesheet-devops'
            }
        }

        stage('DOCKER HUB') {
            when {
                expression { return params.PUSH_DOCKERHUB }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials',
                                                  usernameVariable: 'DH_USER',
                                                  passwordVariable: 'DH_TOKEN')]) {
                    // --password-stdin : le mot de passe n'apparait pas dans la commande
                    sh 'echo "$DH_TOKEN" | docker login -u "$DH_USER" --password-stdin'
                    sh 'docker push "$IMAGE_NAME"'
                }
            }
        }

        stage('DOCKER COMPOSE') {
            steps {
                sh 'docker network create devops-net || true'
                // -d (detached) : les conteneurs tournent en arriere-plan, le pipeline n'est pas bloque
                sh 'docker compose up -d'
                sh 'docker compose ps'
            }
        }

        stage('VERIFICATION APP') {
            steps {
                // Attend (max ~3 min) que Spring Boot reponde "UP" dans le conteneur
                sh '''
                    for i in $(seq 1 36); do
                      if docker exec timesheet-app wget -qO- http://localhost:8082/timesheet-devops/actuator/health; then
                        echo ""; echo "Application demarree"; exit 0
                      fi
                      echo "Attente du demarrage de l'application ($i/36)..."; sleep 5
                    done
                    docker logs --tail 80 timesheet-app
                    exit 1
                '''
            }
        }
    }

    post {
        success {
            echo 'Pipeline termine avec succes'
        }
        failure {
            echo 'Pipeline en echec : ouvrir "Console Output" pour voir le stage fautif'
        }
        always {
            // Mail recapitulatif (plugin Email Extension, SMTP = Mailpit localhost:1025)
            emailext(
                to: params.EMAIL_TO,
                subject: "[Jenkins] ${env.JOB_NAME} #${env.BUILD_NUMBER} : ${currentBuild.currentResult}",
                mimeType: 'text/html',
                attachLog: true,
                body: """
                    <h2>Build ${env.JOB_NAME} #${env.BUILD_NUMBER}</h2>
                    <p><b>Resultat :</b> ${currentBuild.currentResult}</p>
                    <p><b>Duree :</b> ${currentBuild.durationString}</p>
                    <p><b>Image Docker :</b> ${env.IMAGE_NAME}</p>
                    <p><a href="${env.BUILD_URL}">Voir le build dans Jenkins</a> |
                       <a href="http://localhost:9000/dashboard?id=timesheet-devops">SonarQube</a> |
                       <a href="http://localhost:8081/#browse/browse:maven-releases">Nexus</a></p>
                """
            )
        }
    }
}
