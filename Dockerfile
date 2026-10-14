FROM amazoncorretto:17-alpine-jdk

EXPOSE 8080

COPY target/java-maven-app-*.jar app.jar
WORKDIR /usr/app

ENTRYPOINT ["java", "-jar", "app.jar"]