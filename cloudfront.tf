resource "aws_cloudfront_origin_access_identity" "website_OAI" {
  comment = "The OAI used to access our website buckets."
}

locals {
  primary_s3_origin = "${var.root_domain_name}"
  backup_s3_origin = "backup-${var.root_domain_name}"
}

resource "aws_cloudfront_distribution" "website_distribution" {
  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id   = local.primary_s3_origin

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.website_OAI.cloudfront_access_identity_path
    }
  }

  origin {
    domain_name = aws_s3_bucket.backup-website.bucket_regional_domain_name
    origin_id   = local.backup_s3_origin

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.website_OAI.cloudfront_access_identity_path
    }
  }

    origin_group {
    origin_id = "HA-website"

    failover_criteria {
      status_codes = [500, 502, 503, 504]
    }

    member {
      origin_id = local.primary_s3_origin
    }

    member {
      origin_id = local.backup_s3_origin

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
  default_root_object = "index.html"
  custom_error_response {
    error_code = "404"
    response_code = "200"
    response_page_path = "/index.html"
  }
  custom_error_response {
    error_code = "403"
    response_code = "200"
    response_page_path = "/index.html"
  }

  default_cache_behavior {
    viewer_protocol_policy = "${var.cloudfront_viewer_protocol_policy}"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "HA-website"
    cache_policy_id = data.aws_cloudfront_cache_policy.cache_policy.id
    smooth_streaming = false
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


data "aws_cloudfront_cache_policy" "cache_policy" {
  name = "Managed-CachingOptimized"
}

