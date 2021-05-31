FROM python:3.8-slim-buster

RUN apt-get update && apt-get install -y postgresql-client curl git sudo && apt-get clean

RUN groupadd --gid 1000 jenkins && \
    useradd --uid 1000 --gid 1000 --create-home jenkins && \
    echo 'jenkins ALL=NOPASSWD: ALL' >> /etc/sudoers.d/jenkins