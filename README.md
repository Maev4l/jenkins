## Terraform

```
terraform init
```

```
terraform apply -auto-approve
```

## Ansible

```
ansible-galaxy collection install amazon.aws
```

```
ansible-inventory --inventory aws_ec2.yaml --list
```

```
ansible-playbook --inventory aws_ec2.yaml main.yaml
```

## Custom Docker image

```
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin 671123374425.dkr.ecr.eu-central-1.amazonaws.com
```

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

## References

- https://www.digitalocean.com/community/tutorials/how-to-automate-jenkins-setup-with-docker-and-jenkins-configuration-as-code
- https://github.com/awslabs/amazon-ecr-credential-helper#Configuration
- https://blog.nestybox.com/2019/09/29/jenkins.html
