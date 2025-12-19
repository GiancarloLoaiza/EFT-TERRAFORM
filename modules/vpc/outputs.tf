output "vpc_id" {
  description = "El ID de la VPC creada"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Lista de IDs de las subredes públicas creadas"
  # Esto genera una lista con los IDs de todas las subredes creadas por el "count"
  value = aws_subnet.public[*].id
}