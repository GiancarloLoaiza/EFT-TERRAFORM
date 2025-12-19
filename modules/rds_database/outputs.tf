output "db_instance_endpoint" {
  description = "El endpoint de conexión de la instancia RDS"
  value       = module.rds_db.db_instance_endpoint
  sensitive   = true # Oculta la URL en los logs
}