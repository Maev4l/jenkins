packer {
  required_plugins {
    amazon = {
      version = "1.2.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "docker-credential-ecr-login-url" {
  type    = string
  default = "https://amazon-ecr-credential-helper-releases.s3.us-east-2.amazonaws.com/0.6.0/linux-amd64/docker-credential-ecr-login"
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "jenkins-ubuntu-minimal-22.04-${local.timestamp}"
  instance_type = "t2.micro"
  region        = var.region
  source_ami_filter {
    filters = {
      name                = "ubuntu-minimal/images/hvm-ssd/ubuntu-jammy-22.04-amd64-minimal-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"] # Canonical
  }
  ssh_username = "ubuntu"

  tags = {
    "owner"       = "packer"
    "application" = "jenkins"
    "Name"        = "jenkins"
  }
}

build {
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  # see: https://developer.hashicorp.com/packer/docs/debugging#issues-installing-ubuntu-packageshttps://developer.hashicorp.com/packer/docs/debugging#issues-installing-ubuntu-packages
  provisioner "shell" {
    inline = [
      "echo Wait for cloud-init",
      "cloud-init status --wait",
    ]
  }

  provisioner "shell" {
    inline = [
      "echo Update OS",
      "sudo apt-get update",
      "sudo apt-get -qy upgrade",
      "sudo apt-get autoremove",
    ]
  }

  provisioner "shell" {
    inline = [
      "echo Install dependencies",
      "sudo apt-get -qq -y install apt-transport-https unzip ca-certificates curl gnupg lsb-release python3-docker python3-pip",
      "sudo apt-get autoremove",
    ]
  }

  provisioner "shell" {
    inline = [
      "echo Install python dependencies",
      "pip3 install botocore boto3",
    ]
  }

  provisioner "shell" {
    inline = [
      "echo Install docker",
      "sudo mkdir -m 0755 -p /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get update",
      "sudo apt-get -qy install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
      "sudo usermod -aG docker ubuntu",
    ]
  }

  provisioner "shell" {
    inline = [
      "echo Install Amazon ECR credential helper",
      "curl ${var.docker-credential-ecr-login-url} -o docker-credential-ecr-login",
      "sudo mv docker-credential-ecr-login /usr/local/bin",
      "sudo chmod +x /usr/local/bin/docker-credential-ecr-login",
      "mkdir -p ~/.docker",
    ]
  }

  provisioner "file" {
    source      = "docker-config.json"
    destination = "~/.docker/config.json"
  }

  provisioner "shell" {
    inline = [
      "echo Install AWS CLI",
      "curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip",
      "unzip -qq awscliv2.zip",
      "sudo ./aws/install"
    ]
  }
}