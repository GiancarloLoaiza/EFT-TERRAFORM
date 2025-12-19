# ---------------------------------------------------------------
# Archivo: modules/rds_database/main.tf 
# ---------------------------------------------------------------
# Variables necesarias para este módulo
variable "project_name" {
  description = "Nombre del proyecto para etiquetar los recursos"
  type        = string
}
variable "vpc_id" {
  description = "ID de la VPC donde se desplegará la BD"
  type        = string
}
variable "public_subnet_ids" {
  description = "Lista de IDs de las subredes públicas para la BD"
  type        = list(string)
}
# Variables flexibles para la BD
variable "identifier" { 
  description = "Identificador único de la BD" 
  }
variable "db_name" {
  description = "Nombre de la base de datos a crear"
  type        = string
}
variable "db_username" {
  description = "Usuario administrador de la BD"
  type        = string
}
variable "db_password" {
  description = "Contraseña del administrador de la BD"
  type        = string
  sensitive   = true 
}
# Nuevas variables para hacer el módulo genérico
variable "engine" { description = "mysql o postgres" }
variable "engine_version" {}
variable "family" { description = "Familia de parámetros (ej: mysql8.0 o postgres14)" }
variable "db_port" { description = "Puerto de la BD (3306 o 5432)" }

# 1. Security Group Dinámico
resource "aws_security_group" "rds_sg" {
  # CORRECCIÓN: Usamos 'identifier' en lugar de 'project_name' para evitar 
  # nombres duplicados al crear la segunda base de datos.
  name        = "${var.identifier}-sg"
  description = "Security Group para ${var.engine}"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.identifier}-sg" }
}

# 2. Grupo de Subredes
resource "aws_db_subnet_group" "rds_sng" {
  name       = "${var.identifier}-sng"
  subnet_ids = var.public_subnet_ids

  tags = { Name = "${var.identifier}-sng" }
}

# 3. LLAMADA AL MÓDULO PÚBLICO
module "rds_db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.2.0"
  identifier = var.identifier
  engine               = var.engine
  engine_version       = var.engine_version
  family               = var.family
  major_engine_version = var.engine_version # CORRECCIÓN: Usamos la variable, no "8.0" fijo.
  port                 = var.db_port
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  manage_master_user_password = false
  # Red
  create_db_subnet_group = false
  db_subnet_group_name   = aws_db_subnet_group.rds_sng.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible = true
  skip_final_snapshot = true
  tags = {
    Project = var.project_name
  }
}
# Output del endpoint
output "db_endpoint" {
  value = module.rds_db.db_instance_endpoint
}