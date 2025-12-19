# Necesitamos un ID aleatorio para que el nombre del bucket S3 sea único
# (los nombres de S3 deben ser únicos a nivel mundial).
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# 1. Bucket S3 para el sitio web estático
resource "aws_s3_bucket" "static_site" {
  # Usamos el ID aleatorio para asegurar un nombre único
  bucket = "${var.project_name}-static-site-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "${var.project_name}-static-site"
  }
}

# 2. Habilitar el Alojamiento de Sitio Web Estático
resource "aws_s3_bucket_website_configuration" "static_site_config" {
  bucket = aws_s3_bucket.static_site.id

  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}

# 3. Desbloquear el acceso público al bucket
# Por defecto, AWS bloquea todo. Debemos quitar este bloqueo.
resource "aws_s3_bucket_public_access_block" "static_site_access" {
  bucket = aws_s3_bucket.static_site.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# 4. Política de Bucket para permitir lectura pública (Get)
resource "aws_s3_bucket_policy" "static_site_policy" {
  bucket = aws_s3_bucket.static_site.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.static_site.arn}/*"
      }
    ]
  })

  # Importante: Esta política no se puede aplicar HASTA que
  # el "public_access_block" (paso 3) se haya quitado.
  depends_on = [aws_s3_bucket_public_access_block.static_site_access]
}

# 5. Distribución de CloudFront (EL CDN)
# # --- ESTE ES EL RECURSO QUE PUEDE FALLAR ---
# resource "aws_cloudfront_distribution" "cdn" {
#   origin {
#     # Apuntamos al "endpoint" del sitio web del bucket S3
#     domain_name = aws_s3_bucket_website_configuration.static_site_config.website_endpoint
#     origin_id   = aws_s3_bucket.static_site.id

#     # Le decimos a CloudFront que se conecte al bucket por HTTP
#     custom_origin_config {
#       http_port              = 80
#       https_port             = 443
#       origin_protocol_policy = "http-only"
#       origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
#     }
#   }

#   enabled             = true
#   is_ipv6_enabled     = true
#   comment             = "CDN para ${var.project_name}"
#   default_root_object = "index.html"

#   default_cache_behavior {
#     allowed_methods  = ["GET", "HEAD"]
#     cached_methods   = ["GET", "HEAD"]
#     target_origin_id = aws_s3_bucket.static_site.id

#     forwarded_values {
#       query_string = false
#       cookies {
#         forward = "none"
#       }
#     }

#     # Redirige todo el tráfico de HTTP a HTTPS
#     viewer_protocol_policy = "redirect-to-https"
#     min_ttl                = 0
#     default_ttl            = 3600
#     max_ttl                = 86400
#   }

#   # Usamos la clase de precio más barata (solo USA, Canadá, Europa)
#   price_class = "PriceClass_100"

#   restrictions {
#     geo_restriction {
#       restriction_type = "none"
#     }
#   }

#   # Usar el certificado SSL por defecto de CloudFront
#   viewer_certificate {
#     cloudfront_default_certificate = true
#   }

#   tags = {
#     Project = var.project_name
#   }
# }
# 6. Subir el archivo index.html
resource "aws_s3_object" "index_doc" {
  # Apunta al bucket que creamos
  bucket = aws_s3_bucket.static_site.id

  # Nombre que tendrá el archivo DENTRO del bucket
  key = "index.html" 

  # Ruta al archivo en tu PC (relativa a la raíz del proyecto)
  source = var.index_html_path

  # Tipo de contenido para que el navegador lo entienda
  content_type = "text/html"

  # IMPORTANTE: Esto le dice a Terraform que vuelva a subir
  # el archivo solo si su contenido ha cambiado.
  etag = filemd5(var.index_html_path)

  # Depende de que la política del bucket esté aplicada
  depends_on = [aws_s3_bucket_policy.static_site_policy]
}

# 7. Subir el archivo error.html
resource "aws_s3_object" "error_doc" {
  bucket       = aws_s3_bucket.static_site.id
  key          = "error.html"
  source       = var.error_html_path
  content_type = "text/html"
  etag         = filemd5(var.error_html_path)

  depends_on = [aws_s3_bucket_policy.static_site_policy]
}
# 8. Subir la imagen logo.png
resource "aws_s3_object" "logo_img" {
  bucket       = aws_s3_bucket.static_site.id
  key          = "logo.png" # Nombre que tendrá en el bucket
  source       = var.image_path
  content_type = "image/png" # El tipo de contenido
  etag         = filemd5(var.image_path)

  depends_on = [aws_s3_bucket_policy.static_site_policy]
}