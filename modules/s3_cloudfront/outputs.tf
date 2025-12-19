output "s3_bucket_website_endpoint" {
  description = "Endpoint del sitio web estático S3 (acceso directo)"
  value       = aws_s3_bucket_website_configuration.static_site_config.website_endpoint
}

# output "cloudfront_domain_name" {
#   description = "Dominio del CDN CloudFront (acceso preferido)"
#   value       = aws_cloudfront_distribution.cdn.domain_name
# }