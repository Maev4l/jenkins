# Jenkins

Setup a Jenkins server

## Packer

Build an AMI with:

- docker
- AWS CLI

Inside packer folder

```shell
packer build .
```

## Terraform

Build the infrastructure, mainly EC2 instances

```
terraform init
```

```
terraform apply -auto-approve
```

## Ansible

- install: Playbook to deploy a containerized Jenkins controller (behind a containerized reverse proxy)
- start-stop: Start / Stop the EC2 instances

```
ansible-galaxy collection install amazon.aws
ansible-galaxy collection install community.aws
```

```
ansible-inventory --inventory aws_ec2.yaml --list
```

```
ansible-playbook ./install/main.yaml --extra-vars "@vars.yml" --extra-vars "jenkins_username=<admin_name> jenkins_userpassword=<admin_password>"
```

## Custom Docker image for Jenkins

```
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin 671123374425.dkr.ecr.eu-central-1.amazonaws.com
```

### Jenkins

```
docker build -t jenkins:1.0 .
```

```
docker tag jenkins:1.0 671123374425.dkr.ecr.eu-central-1.amazonaws.com/jenkins:1.0
```

```
docker push 671123374425.dkr.ecr.eu-central-1.amazonaws.com/jenkins:1.0
```

(optional: run locally)

```
docker run --name jenkins --rm -p 8080:8080 --env JENKINS_ADMIN_ID=admin --env JENKINS_ADMIN_PASSWORD=password jenkins:1.0
```

### NodeJS

```
docker build -t jenkins/nodejs:14 .
```

```
docker tag jenkins/nodejs:14 671123374425.dkr.ecr.eu-central-1.amazonaws.com/jenkins/nodejs:14
```

```
docker push 671123374425.dkr.ecr.eu-central-1.amazonaws.com/jenkins/nodejs:14
```

### Python

```
docker build -t jenkins/python:3.8 .
```

```
docker tag jenkins/python:3.8 671123374425.dkr.ecr.eu-central-1.amazonaws.com/jenkins/python:3.8
```

```
docker push 671123374425.dkr.ecr.eu-central-1.amazonaws.com/jenkins/python:3.8
```

## Notes

The Jenkins controller instance IP address is referenced by a Route53 DNS record, therefore when the instance is restarted, we have to update the DNS record with the new allocated public IP address.
This task is performed by an AWS Lambda function listening to the EC2 instances state change notifications.
This saves us the cost of an Elastic IP.

## References

- https://www.digitalocean.com/community/tutorials/how-to-automate-jenkins-setup-with-docker-and-jenkins-configuration-as-code
- https://github.com/awslabs/amazon-ecr-credential-helper#Configuration
- https://blog.nestybox.com/2019/09/29/jenkins.html
