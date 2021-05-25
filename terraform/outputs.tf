output "master_public_dns" {
  value = aws_instance.master.public_dns
}

output "master_public_ip" {
  value = aws_instance.master.public_ip
}


