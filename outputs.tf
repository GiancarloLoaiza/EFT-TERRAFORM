output "vpc_id" {
  description = "ID de la VPC principal"
  value       = module.vpc.vpc_id
}
output "public_subnet_ids" {
  description = "IDs de las subredes públicas"
  value       = module.vpc.public_subnet_ids
}
# --- Outputs para las 2 Bases de Datos ---
output "postgres_app1_endpoint" {
  description = "Endpoint de conexión para App 1 (Postgres)"
  value       = module.db_app1_postgres.db_endpoint
  sensitive   = true
}
output "mysql_app2_endpoint" {
  description = "Endpoint de conexión para App 2 (MySQL)"
  value       = module.db_app2_mysql.db_endpoint
  sensitive   = true
}
# Output seguro: Si el módulo no se crea, esto devuelve null en lugar de error
output "s3_website_url" {
  description = "URL del sitio estático (si está habilitado)"
  value       = length(module.s3_cloudfront) > 0 ? module.s3_cloudfront[0].s3_bucket_website_endpoint : "Frontend Deshabilitado"
}
output "app1_linux_ips" {
  description = "IPs Públicas de los servidores Linux"
  value       = module.app1_linux_compute.instance_ips
}
output "app2_windows_ips" {
  description = "IPs Públicas de los servidores Windows"
  value       = module.app2_windows_compute.instance_ips
}
output "alb_app1_linux_url" {
  description = "URL del Balanceador para App 1 (Linux)"
  value       = "http://${module.alb_app1.dns_name}"
}
output "alb_app2_windows_url" {
  description = "URL del Balanceador para App 2 (Windows)"
  value       = "http://${module.alb_app2.dns_name}"
}