FROM eclipse-temurin:17-jdk-alpine AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN apk add --no-cache maven && mvn -q -DskipTests package

FROM eclipse-temurin:17-jre-alpine
# Librerías gráficas mínimas para procesar las fotos de restaurantes (Java2D/ImageIO)
RUN apk add --no-cache fontconfig freetype
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
# Render gratis da 512 MB: por defecto Java usa solo el 25 % para el heap
# (~128 MB) y una foto en base64 puede agotarlo. Se permite usar el 75 %.
ENTRYPOINT ["java", "-Djava.awt.headless=true", "-XX:MaxRAMPercentage=75", "-XX:+ExitOnOutOfMemoryError", "-jar", "app.jar"]
