output "backend_alb_url" {
  description = "URL pública del Load Balancer del Backend"
  # Agregamos http:// para que sea una URL clickeable
  value = "http://${aws_lb.backend_alb.dns_name}"
}

output "frontend_server_url" {
  description = "URL pública del Servidor Web (Emulador CDN)"
  value = "http://${aws_instance.frontend_server.public_ip}"
}