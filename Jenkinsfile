// =====================================================================
//  Pipeline CI/CD - timesheet-devops
//  GIT -> DATE -> MVN CLEAN/COMPILE -> MOCKITO/JUNIT -> MVN PACKAGE
//      -> DOCKER IMAGE -> DOCKER HUB -> DOCKER COMPOSE -> VERIFICATION -> MAIL
// =====================================================================
pipeline {
    agent any

    tools {
        jdk 'JDK17'
        maven 'M2_HOME'
    }

    environment {
        DOCKERHUB_USER = 'salim145'
        IMAGE_REPO     = 'salim145/timesheet-devops'
        APP_VERSION    = "1.${BUILD_NUMBER}"
    }

    triggers {
        pollSCM('H/2 * * * *')
    }

    options {
        skipDefaultCheckout()
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

        stage('VERSION') {
            steps {
                sh '''
                    echo "Version Jenkins : 1.${BUILD_NUMBER}"

                    mvn -B versions:set \
                        -DnewVersion=1.${BUILD_NUMBER} \
                        -DgenerateBackupPoms=false

                    echo "Version actuelle :"
                    grep -n "<version>" pom.xml | head
                '''
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
                sh 'mvn -B test'
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: 'target/surefire-reports/*.xml'
                }
            }
        }

        stage('MVN PACKAGE') {
            steps {
                sh 'mvn -B package -DskipTests'
            }
        }

        stage('DOCKER IMAGE') {
            steps {
                sh '''
                    echo "IMAGE_REPO = ${IMAGE_REPO}"
                    echo "APP_VERSION = ${APP_VERSION}"

                    docker build \
                        --build-arg APP_VERSION=${APP_VERSION} \
                        -t ${IMAGE_REPO}:${APP_VERSION} .
                '''
            }
        }
    }
}
