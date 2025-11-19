FROM maven:3.9.6-eclipse-temurin-17 AS build

WORKDIR /app

COPY pom.xml .
COPY src ./src

ENTRYPOINT ["mvn", "spring-boot:run"]