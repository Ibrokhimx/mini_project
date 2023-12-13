output "my_eip" {
  value = { for k, v in aws_eip.nat : k => v.public_ip }
}