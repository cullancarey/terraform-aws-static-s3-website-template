variable "root_domain_name" {
  type = string
  description = "The domain name of your website."
}

variable "cron_schedule" {
  type = string
  default = "cron(0 6 1 * ? *)"
  description = "A cron job specifying how often the lambda is triggered to update the secret string."
}

variable "website-bucket-region" {
  type = string
  description = "The primary region where your website will be hosted."
}

variable "backup-website-bucket-region" {
  type = string
  description = "The region where your backup bucket will be located."
}

variable "cloudfront_price_class" {
  type        = string
  description = "The price class for the Cloudfront distribution. Valid entries are PriceClass_All, PriceClass_200, or PriceClass_100."
  default = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.cloudfront_price_class)
    error_message = "Valid values for var: cloudfront_price_class are PriceClass_All, PriceClass_200, or PriceClass_100."
  } 
}