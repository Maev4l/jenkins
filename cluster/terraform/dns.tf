data "aws_acm_certificate" "main_certificate" {
  provider = aws.us-east-1
  domain   = "*.isnan.eu"
  types    = ["IMPORTED"]
}

data "aws_route53_zone" "primary" {
  name = "isnan.eu."
}

locals {
  jenkins_dns_name = "jenkins.isnan.eu"
  bastion_dns_name = "bastion.jenkins.isnan.eu"
}

resource "aws_route53_record" "jenkins_controller_ipv4" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = local.jenkins_dns_name
  type    = "A"
  ttl     = 300

  records = [aws_instance.controller.public_ip]
}

resource "aws_route53_record" "jenkins_bastion_ipv4" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = local.bastion_dns_name
  type    = "A"
  ttl     = 300

  records = [aws_instance.bastion.public_ip]
}

