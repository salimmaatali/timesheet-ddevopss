# Image de l'application Spring Boot timesheet-devops.
# L'image openjdk:*-alpine du cours n'est plus publiee sur Docker Hub :
# eclipse-temurin est l'image Java officielle qui la remplace.
FROM eclipse-temurin:17-jre-alpine

LABEL maintainer="equipe-devops"

WORKDIR /app

# Le jar est produit par "mvn package" (stage Jenkins) dans target/
ARG JAR_FILE=target/timesheet-devops-1.0.jar
ADD ${JAR_FILE} timesheet-devops-1.0.jar

EXPOSE 8082

ENTRYPOINT ["java", "-jar", "/app/timesheet-devops-1.0.jar"]
