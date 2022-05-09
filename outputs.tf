output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.website_distribution.id
  description = "The ID of the Cloudfront distribution."
}

output "cloudfront_distribution_domain_name" {
  value = aws_cloudfront_distribution.website_distribution.domain_name
  description = "The domain name of the Cloudfront distribution."
}

output "primary_bucket_arn" {
  value = aws_s3_bucket.website.arn
  description = "The arn of the primary website bucket."
}

output "route53_zone_arn" {
  value = data.aws_route53_zone.root_zone.arn
  description = "The arn of the route53 hosted zone."
}

output "acm_domain_name" {
  value = aws_acm_certificate.certificate.domain_name
  description = "The domain names that are associated to the ACM certificate."
}

