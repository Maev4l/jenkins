locals {
  ebs_device_suffix  = "df"
  master_mount_point = "/data"
}

resource "aws_key_pair" "jenkins_key" {
  key_name   = "jenkins-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

data "aws_s3_bucket" "certificates_bucket" {
  bucket = "letsencrypt-lambda-storage"
}

resource "aws_iam_role" "master_ec2_role" {
  name = "${local.tags.application}-master-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "${local.tags.application}-master-role-policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = ["s3:ListBucket", "s3:GetObject", "s3:HeadBucket"]
          Effect = "Allow"
          Resource = [
            "${data.aws_s3_bucket.certificates_bucket.arn}",
            "${data.aws_s3_bucket.certificates_bucket.arn}/full",
            "${data.aws_s3_bucket.certificates_bucket.arn}/certificate",
            "${data.aws_s3_bucket.certificates_bucket.arn}/intermediate",
            "${data.aws_s3_bucket.certificates_bucket.arn}/root",
            "${data.aws_s3_bucket.certificates_bucket.arn}/certificateKey"
          ]
        },
        {
          Action   = ["s3:HeadBucket"]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = [
            "ecr:GetAuthorizationToken",
            "ecr:DescribeRepositories",
            "ecr:ListImages",
            "ecr:DescribeImages",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:GetRepositoryPolicy",
            "ecr:BatchGetImage"
          ]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }
}

resource "aws_iam_instance_profile" "master_profile" {
  name = "${local.tags.application}-master-profile"
  role = aws_iam_role.master_ec2_role.name
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


resource "aws_instance" "master" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.small"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg.id]
  subnet_id                   = aws_subnet.subnet1.id
  key_name                    = aws_key_pair.jenkins_key.key_name
  iam_instance_profile        = aws_iam_instance_profile.master_profile.id
  user_data                   = templatefile("mount.tpl", { mount_point = local.master_mount_point, device = "/dev/xv${local.ebs_device_suffix}" })

  ebs_block_device {
    delete_on_termination = true
    device_name           = "/dev/s${local.ebs_device_suffix}"
    volume_size           = 100
    volume_type           = "gp2"
    tags = {
      node = "master"
    }
  }

  tags = {
    node = "master"
  }
}

