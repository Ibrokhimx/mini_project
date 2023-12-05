output "my_eip" {
  value = { for k, v in aws_eip.eip : k => v.public_ip }
}