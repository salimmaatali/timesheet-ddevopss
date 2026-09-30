# Image de l'application Spring Boot timesheet-devops.
# L'image openjdk:*-alpine du cours n'est plus publiee sur Docker Hub :
# eclipse-temurin est l'image Java officielle qui la remplace.
# Image Java officielle pour exécuter Spring Boot
FROM eclipse-temurin:17-jre-alpine

LABEL maintainer="equipe-devops"

WORKDIR /app

# JAR généré par Maven
ARG JAR_FILE=target/timesheet-devops-1.2.jar

COPY ${JAR_FILE} timesheet-devops-1.2.jar

EXPOSE 8082

ENTRYPOINT ["java", "-jar", "timesheet-devops-1.2.jar"]
