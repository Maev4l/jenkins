FROM jenkins/jenkins:2.277.4-lts-alpine

USER root

RUN apk update && apk add --no-cache docker-cli

USER jenkins
# Disable the installation wizard
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false

ENV CASC_JENKINS_CONFIG /home/casc.yaml

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt
COPY casc.yaml /home/casc.yaml