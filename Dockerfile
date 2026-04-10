FROM tomcat:10.1-jdk17-temurin

WORKDIR /usr/local/tomcat

RUN rm -rf webapps/*

# ✅ FIX: match ROOT-v2.war and deploy as ROOT.war
COPY target/*.war webapps/ROOT.war

EXPOSE 8080
CMD ["catalina.sh", "run"]

