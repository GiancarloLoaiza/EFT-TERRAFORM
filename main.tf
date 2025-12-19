# Llama a nuestro módulo local que está en la carpeta modules/vpc
module "vpc" {
  source = "./modules/vpc" # La ruta a la carpeta del módulo

  # Aquí le pasamos las variables que el módulo necesita
  project_name        = var.project_name
  vpc_cidr_block      = var.vpc_cidr_block
  public_subnet_cidrs = var.public_subnet_cidrs
}
# ---------------------------------------------------------
# BASE DE DATOS 1: POSTGRES (Para App 1)
# ---------------------------------------------------------
module "db_app1_postgres" {
  source = "./modules/rds_database"

  project_name      = var.project_name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids

  # Configuración específica para Postgres
  identifier     = "${var.project_name}-postgres-app1"
  engine         = "postgres"
  engine_version = "14"       # Versión 14 de Postgres
  family         = "postgres14"
  db_port        = 5432
  
  db_name     = "app1_db"
  db_username = "postgres"    # Usuario por defecto en Postgres
  db_password = var.db_password
  # Dependencia explícita
  depends_on = [ module.vpc ]
}
# ---------------------------------------------------------
# BASE DE DATOS 2: MYSQL (Para App 2)
# ---------------------------------------------------------
module "db_app2_mysql" {
  source = "./modules/rds_database"

  project_name      = var.project_name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids

  # Configuración específica para MySQL
  identifier     = "${var.project_name}-mysql-app2"
  engine         = "mysql"
  engine_version = "8.0"
  family         = "mysql8.0"
  db_port        = 3306
  
  db_name     = "app2_db"
  db_username = "admin"
  db_password = var.db_password
  # Dependencia explícita
  depends_on = [ module.vpc ]
}
module "s3_cloudfront" {
  source = "./modules/s3_cloudfront"
  # --- LÓGICA CONDICIONAL (Requerimiento) ---
  # Si la variable enabled_frontend es true, count es 1 (se crea).
  # Si es false, count es 0 (se destruye/no se crea).
  count = var.enabled_frontend ? 1 : 0
  project_name = var.project_name
  index_html_path = var.index_html_path
  error_html_path = var.error_html_path
  image_path      = var.image_path
}
# --- 1. Security Group compartido para los servidores ---
resource "aws_security_group" "servers_sg" {
  name        = "${var.project_name}-servers-sg"
  description = "Permite trafico web"
  vpc_id      = module.vpc.vpc_id
  # --- BUCLE FOR_EACH (Requerimiento) ---
  # Crea una regla de entrada por cada IP en la lista var.allowed_ips
  dynamic "ingress" {
    for_each = var.allowed_ips # Itera sobre ["0.0.0.0/0"] u otras IPs
    content {
      description = "Acceso HTTP permitido desde IP confiable"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = [ingress.value] # ingress.value es la IP actual del bucle
    }
  }
  # ingress {
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
  
  # RDP para Windows
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # SSH para Linux
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# ---------------------------------------------------------
# APP 1: LINUX (3 Instancias)
# ---------------------------------------------------------
module "app1_linux_compute" {
  source = "./modules/compute"
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  # Ponemos las instancias en la primera subred pública
  subnet_id          = module.vpc.public_subnet_ids[0]
  security_group_ids = [aws_security_group.servers_sg.id]
  # Lógica
  os_type        = "linux"
  instance_count = var.instance_count_app1 # Variable definida en variables.tf (valor 3)
}
# ---------------------------------------------------------
# APP 2: WINDOWS (2 Instancias)
# ---------------------------------------------------------
module "app2_windows_compute" {
  source = "./modules/compute"
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  # Ponemos las instancias en la segunda subred pública
  subnet_id          = module.vpc.public_subnet_ids[1]
  security_group_ids = [aws_security_group.servers_sg.id]
  # Lógica
  os_type        = "windows"
  instance_count = 2 # Valor fijo según requerimiento del diagrama
}
# ---------------------------------------------------------
# BALANCEADOR DE CARGA APP 1 (LINUX)
# ---------------------------------------------------------
module "alb_app1" {
  source = "./modules/alb"
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  # El ALB debe estar en todas las subredes públicas para alta disponibilidad
  subnet_ids   = module.vpc.public_subnet_ids
  app_name     = "app1-linux"
  # Aquí ocurre la magia: Le pasamos los IDs que salen del módulo de cómputo Linux
  instance_ids = module.app1_linux_compute.instance_ids
}
# ---------------------------------------------------------
# BALANCEADOR DE CARGA APP 2 (WINDOWS)
# ---------------------------------------------------------
module "alb_app2" {
  source = "./modules/alb"
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.public_subnet_ids
  app_name     = "app2-windows"
  # Le pasamos los IDs que salen del módulo de cómputo Windows
  instance_ids = module.app2_windows_compute.instance_ids
}
# module "backend_servers" {
#   source = "./modules/backend_servers"

#   project_name      = var.project_name
#   vpc_id            = module.vpc.vpc_id
#   public_subnet_ids = module.vpc.public_subnet_ids

#   # Pasamos la URL del bucket S3 y el nombre de la imagen
#   s3_website_url = module.s3_cloudfront.s3_bucket_website_endpoint
#   s3_image_name  = var.s3_image_name

#   # Depende de que el S3 y la VPC estén listos
#   depends_on = [
#     module.s3_cloudfront,
#     module.vpc
#   ]
# }