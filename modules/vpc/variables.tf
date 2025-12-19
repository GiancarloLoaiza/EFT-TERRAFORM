variable "project_name" {
  description = "Nombre del proyecto para etiquetar los recursos"
  type        = string
}

variable "vpc_cidr_block" {
  description = "Rango de IPs para la VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Lista de rangos de IPs para las subredes públicas"
  type        = list(string)
}