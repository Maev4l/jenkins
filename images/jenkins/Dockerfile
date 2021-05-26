# Build amazon-ecr-credential-helper
# so the Jenkins container can connect to the ECR
FROM golang:alpine AS builder
RUN apk --no-cache add git
RUN go env -w GO111MODULE=auto
RUN git clone https://github.com/awslabs/amazon-ecr-credential-helper /go/src/github.com/awslabs/amazon-ecr-credential-helper && \
    go build -o /assets/docker-credential-ecr-login github.com/awslabs/amazon-ecr-credential-helper/ecr-login/cli/docker-credential-ecr-login

FROM jenkins/jenkins:2.277.4-lts-alpine

COPY --from=builder /assets/docker-credential-ecr-login /usr/local/bin/docker-credential-ecr-login

USER root

RUN apk update && apk add --no-cache docker-cli

USER jenkins
# Disable the installation wizard
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false

ENV CASC_JENKINS_CONFIG /home/casc.yaml
ENV DOCKER_CONFIG /home/.docker

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt
COPY casc.yaml /home/casc.yaml

COPY docker-config.json /home/.docker/config.json