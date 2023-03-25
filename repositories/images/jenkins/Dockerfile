# Build amazon-ecr-credential-helper
# so the Jenkins container can connect to the ECR
FROM golang:alpine AS builder
ARG ECR_CREDENTIALS_HELPER_VERSION=v0.6.0
RUN apk --no-cache add git
RUN go env -w GO111MODULE=auto
RUN git clone -b ${ECR_CREDENTIALS_HELPER_VERSION} --single-branch https://github.com/awslabs/amazon-ecr-credential-helper /go/src/github.com/awslabs/amazon-ecr-credential-helper && \
    go build -o /assets/docker-credential-ecr-login github.com/awslabs/amazon-ecr-credential-helper/ecr-login/cli/docker-credential-ecr-login

FROM jenkins/jenkins:2.387.1-lts-alpine

COPY --from=builder /assets/docker-credential-ecr-login /usr/local/bin/docker-credential-ecr-login

USER root

RUN chmod +x /usr/local/bin/docker-credential-ecr-login

RUN apk update && apk add --no-cache docker-cli

USER jenkins
# Disable the installation wizard
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false

ENV CASC_JENKINS_CONFIG /home/casc.yaml
ENV DOCKER_CONFIG /home/.docker

COPY plugins.txt /plugins.txt
RUN jenkins-plugin-cli --plugin-file /plugins.txt
COPY casc.yaml /home/casc.yaml

COPY docker-config.json /home/.docker/config.json