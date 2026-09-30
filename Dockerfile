# Image de l'application Spring Boot timesheet-devops.
# L'image openjdk:*-alpine du cours n'est plus publiee sur Docker Hub :
# eclipse-temurin est l'image Java officielle qui la remplace.
# Image Java officielle pour exécuter Spring Boot
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

ARG APP_VERSION

COPY target/timesheet-devops-${APP_VERSION}.jar app.jar

EXPOSE 8082

ENTRYPOINT ["java", "-jar", "app.jar"]
