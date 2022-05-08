resource "random_string" "header_value" {
  length           = 20
  special          = true
  upper = true
  lower = true
  number = true
}

resource "aws_cloudfront_distribution" "website_distribution" {
  origin {
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }

    domain_name = "${aws_s3_bucket_website_configuration.website-bucket-config.website_endpoint}"
    origin_id   = "${var.root_domain_name}"
    custom_header {
          name  = "${var.custom_header}"
          value = random_string.header_value.result
        }
  }

  origin {
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }

    domain_name = "${aws_s3_bucket_website_configuration.backup-website-bucket-config.website_endpoint}"
    origin_id   = "backup-${var.root_domain_name}"
    custom_header {
          name  = "${var.custom_header}"
          value = random_string.header_value.result
        }
  }

    origin_group {
    origin_id = "HA-website"

    failover_criteria {
      status_codes = [500, 502, 503, 504]
    }

    member {
      origin_id = "${var.root_domain_name}"
    }

    member {
      origin_id = "backup-${var.root_domain_name}"
    }
  }


  aliases = ["${var.root_domain_name}", "www.${var.root_domain_name}"]
  enabled             = true
  comment = "Distribution for ${var.root_domain_name}" 
  price_class = "PriceClass_100"
  wait_for_deployment = true
  tags = {
    Name = "website_distribution"
  }

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "HA-website"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    smooth_streaming = false
    forwarded_values {
              headers                 = [] 
              query_string            = false 
              query_string_cache_keys = [] 

              cookies {
                  forward           = "none" 
                  whitelisted_names = [] 
                }
            }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = "${aws_acm_certificate.certificate.arn}"
    ssl_support_method  = "sni-only"
    cloudfront_default_certificate = false
    minimum_protocol_version = "TLSv1.2_2021"
  }
}