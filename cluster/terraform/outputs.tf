output "bastion_public_dns" {
  value = aws_instance.bastion.public_dns
}

output "controller_private_dns" {
  value = aws_instance.controller.private_dns
}


