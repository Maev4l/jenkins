data "aws_ami" "jenkins_image" {
  most_recent = true
  owners      = ["self"]
  filter {
    name   = "name"
    values = ["jenkins-ubuntu-*"]
  }
}
