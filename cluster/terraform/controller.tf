data "aws_s3_bucket" "certificates_bucket" {
  bucket = "letsencrypt-lambda-storage"
}

resource "aws_iam_policy" "controller_policy" {
  name        = "jenkins-controller-policy"
  path        = "/"
  description = "Role for jenkins controller EC2 instance"
  policy = jsonencode({
    Version = "2012-10-17",
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
        Effect : "Allow",
        Action : [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage"
        ]
        Resource : "*"
    }]
  })
}

resource "aws_iam_role" "controller_role" {
  name = "jenkins-controller-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy_attachment" "controller_policy_role" {
  name       = "jenkins-controller-policy-role"
  roles      = [aws_iam_role.controller_role.name]
  policy_arn = aws_iam_policy.controller_policy.arn
}

resource "aws_iam_instance_profile" "controller_profile" {
  name = "jenkins-controller-profile"
  role = aws_iam_role.controller_role.name
}

locals {
  ebs_device_suffix  = "df"
  master_mount_point = "/data"
}

resource "aws_security_group" "sg_controller_instance" {
  name        = "jenkins-controller-sg"
  description = "Security group for jenkins controller"
  vpc_id      = aws_vpc.main.id
}

// Allow only incoming SSH requests from the bastion
resource "aws_vpc_security_group_ingress_rule" "ingress_rule_ssh_controller" {
  security_group_id            = aws_security_group.sg_controller_instance.id
  referenced_security_group_id = aws_security_group.sg_bastion.id
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
}

resource "aws_vpc_security_group_ingress_rule" "ingress_rule_https_controller" {
  security_group_id = aws_security_group.sg_controller_instance.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}


// Allow all outgoing requests
resource "aws_vpc_security_group_egress_rule" "egress_rules_controller" {
  security_group_id = aws_security_group.sg_controller_instance.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_ebs_volume" "controller_volume" {
  availability_zone = data.aws_availability_zones.azs.names[0]
  size              = 100
  type              = "gp2"

  tags = {
    Name = "jenkins-controller-volume"
  }
}

resource "aws_instance" "controller" {
  ami                         = data.aws_ami.jenkins_image.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg_controller_instance.id]
  subnet_id                   = aws_subnet.public_subnet[0].id
  key_name                    = aws_key_pair.public_key.key_name
  iam_instance_profile        = aws_iam_instance_profile.controller_profile.id
  user_data                   = templatefile("controller-startup.tftpl", { mount_point = local.master_mount_point, device = "/dev/xv${local.ebs_device_suffix}" })

  tags = {
    Name = "jenkins-controller"
    role = "controller"
  }
}

resource "aws_volume_attachment" "ebs_controller_attachment" {
  device_name = "/dev/s${local.ebs_device_suffix}"
  volume_id   = aws_ebs_volume.controller_volume.id
  instance_id = aws_instance.controller.id
}
