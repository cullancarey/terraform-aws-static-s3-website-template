data "aws_caller_identity" "current" {}

locals {
  account_id        = data.aws_caller_identity.current.account_id
  primary_s3_origin = var.root_domain_name
  backup_s3_origin  = "backup-${var.root_domain_name}"
}