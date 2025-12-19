variable "aws_region" {
  description = "Región de AWS donde se desplegarán los recursos."
  type        = string
  default     = "us-east-1" # us-east-1 es la estándar en Learner Lab
}
variable "project_name" {
  description = "Nombre del proyecto, usado para etiquetar recursos."
  type        = string
}

variable "vpc_cidr_block" {
  description = "Rango de IPs para la VPC."
  type        = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Lista de rangos de IPs para las subredes públicas."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}
variable "db_name" {
  description = "Nombre de la base de datos"
  type        = string
  default     = "mi_db"
}

variable "db_username" {
  description = "Usuario admin para la BD"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Password para las BD"
  type        = string
  sensitive   = true # Oculta el valor en los logs buen practica
}
variable "index_html_path" {
  description = "Ruta al archivo index.html en el disco local"
  type        = string
  default     = "index.html"
}

variable "error_html_path" {
  description = "Ruta al archivo error.html en el disco local"
  type        = string
  default     = "error.html"
}
variable "image_path" {
  description = "Ruta a la imagen logo.png en el disco local"
  type        = string
  default     = "logo.png"
}
variable "s3_image_name" {
  description = "Nombre del archivo de imagen en S3"
  type        = string
  default     = "logo.png"
}
variable "env" {
  description = "Entorno de despliegue (dev, prod, etc.) para usar con funciones upper()"
  type        = string
  default     = "lab"
}
# --- Variables de Control Lógico (Requerimiento 2) ---

variable "enabled_frontend" {
  description = "Si es true, crea el bucket S3. Si es false, no lo crea."
  type        = bool
  default     = true
}

variable "instance_count_app1" {
  description = "Cantidad de instancias para la App 1 (Linux)"
  type        = number
  default     = 3
}

variable "allowed_ips" {
  description = "Lista de IPs permitidas para el Security Group (Uso de for_each)"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Por defecto abierto, pero probaremos restringirlo
}