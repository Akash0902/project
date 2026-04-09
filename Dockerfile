FROM tomcat:10-jdk21

WORKDIR /usr/local/tomcat

# Remove default apps
RUN rm -rf webapps/*

# Copy ANY WAR produced by Maven
COPY target/*.war webapps/ROOT.war

EXPOSE 8082

CMD ["catalina.sh", "run"]FROM tomcat:10-jdk21

