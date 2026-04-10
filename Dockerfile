FROM tomcat:10.1-jdk17-temurin

WORKDIR /usr/local/tomcat

# Remove default Tomcat apps
RUN rm -rf webapps/*

# Copy WAR produced by Maven
COPY target/ROOT.war webapps/ROOT.war

# Tomcat internal port
EXPOSE 8080

CMD ["catalina.sh", "run"]
