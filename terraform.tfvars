# Valores para el proyecto
project_name = "mi-proyecto-eva3"
env          = "development"
# Control lógico
enabled_frontend    = true # habilitar o deshabilitar el frontend S3+CloudFront
instance_count_app1 = 3     # Diagrama pide 3 servidores para App 1
allowed_ips = ["0.0.0.0/0"]  # Permitir acceso desde cualquier IP (para pruebas)
# Valores para la VPC (crearemos una VPC 10.0.0.0/16)
vpc_cidr_block = "10.0.0.0/16"

# Crearemos 2 subredes públicas
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]

# !! IMPORTANTE: Se elige una contraseña de al menos 8 caracteres.
db_password = "Duoc.9999"