variable "project_name" {
  description = "Nombre del proyecto para etiquetar"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC para los recursos"
  type        = string
}

variable "public_subnet_ids" {
  description = "Lista de IDs de las subredes públicas"
  type        = list(string)
}

variable "s3_website_url" {
  description = "Endpoint (URL) del bucket S3"
  type        = string
}

variable "s3_image_name" {
  description = "Nombre del archivo de imagen en el bucket S3"
  type        = string
}