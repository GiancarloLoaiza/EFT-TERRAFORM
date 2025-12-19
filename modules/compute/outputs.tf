output "instance_ids" {
  description = "Lista de IDs de las instancias creadas"
  value       = aws_instance.server[*].id
}