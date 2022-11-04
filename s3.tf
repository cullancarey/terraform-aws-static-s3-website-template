resource "aws_s3_bucket" "website" {
  bucket        = var.root_domain_name
  force_destroy = true
  tags = {
    Name = "website-bucket-s3-static-website"
  }
}

resource "aws_s3_bucket_public_access_block" "s3Public" {
  bucket                  = aws_s3_bucket.website.id
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket_website_configuration" "website-bucket-config" {
  bucket = aws_s3_bucket.website.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_versioning" "website-bucket-versioning" {
  bucket = aws_s3_bucket.website.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_replication_configuration" "website-bucket-replication" {
  # Must have bucket versioning enabled first
  depends_on = [aws_s3_bucket_versioning.website-bucket-versioning]

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.website.id

  rule {
    id     = "backup-website"
    status = "Enabled"
    destination {
      bucket = aws_s3_bucket.backup-website.arn
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "website-bucket-lifecycle-rule" {
  bucket = aws_s3_bucket.website.id

  rule {
    id     = "delete versions"
    status = "Enabled"
    noncurrent_version_expiration {
      noncurrent_days = 2
    }
  }
}

resource "aws_s3_bucket_policy" "website-bucket-policy" {
  bucket = aws_s3_bucket.website.id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": {
        "Sid": "AllowCloudFrontServicePrincipalReadOnly",
        "Effect": "Allow",
        "Principal": {
            "Service": "cloudfront.amazonaws.com"
        },
        "Action": "s3:GetObject",
        "Resource": "${aws_s3_bucket.website.arn}/*",
        "Condition": {
            "StringEquals": {
                "AWS:SourceArn": "${aws_cloudfront_distribution.website_distribution.arn}"
            }
        }
    }
}

POLICY
}

################################################################################################################################################
################################################################################################################################################
################################################################################################################################################


##BACK UP WEBSITE BUCKET##
resource "aws_s3_bucket" "backup-website" {
  bucket        = "backup-${var.root_domain_name}"
  force_destroy = true
  provider      = aws.backup-website-region
  tags = {
    Name = "backup-website-bucket-s3-static-website"
  }
}

resource "aws_s3_bucket_public_access_block" "backup-s3Public" {
  bucket                  = aws_s3_bucket.backup-website.id
  provider                = aws.backup-website-region
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}


resource "aws_s3_bucket_website_configuration" "backup-website-bucket-config" {
  bucket   = aws_s3_bucket.backup-website.bucket
  provider = aws.backup-website-region

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_versioning" "backup-website-bucket-versioning" {
  bucket   = aws_s3_bucket.backup-website.id
  provider = aws.backup-website-region
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "website-backup-bucket-lifecycle-rule" {
  bucket   = aws_s3_bucket.backup-website.id
  provider = aws.backup-website-region

  rule {
    id     = "delete versions"
    status = "Enabled"
    noncurrent_version_expiration {
      noncurrent_days = 2
    }
  }
}

resource "aws_s3_bucket_policy" "backup-website-bucket-policy" {
  bucket   = aws_s3_bucket.backup-website.id
  provider = aws.backup-website-region
  policy   = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": {
        "Sid": "AllowCloudFrontServicePrincipalReadOnly",
        "Effect": "Allow",
        "Principal": {
            "Service": "cloudfront.amazonaws.com"
        },
        "Action": "s3:GetObject",
        "Resource": "${aws_s3_bucket.backup-website.arn}/*",
        "Condition": {
            "StringEquals": {
                "AWS:SourceArn": "${aws_cloudfront_distribution.website_distribution.arn}"
            }
        }
    }
}

POLICY
}


resource "aws_iam_role" "replication" {
  name = "s3crr_role_for_${var.root_domain_name}"
  path = "/service-role/"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}

POLICY
}


resource "aws_iam_policy" "s3_replication_exec_policy" {
  name   = "s3crr_policy_for_${var.root_domain_name}"
  path   = "/service-role/"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "s3:ListBucket",
                "s3:GetReplicationConfiguration",
                "s3:GetObjectVersionForReplication",
                "s3:GetObjectVersionAcl",
                "s3:GetObjectVersionTagging",
                "s3:GetObjectRetention",
                "s3:GetObjectLegalHold"
            ],
            "Effect": "Allow",
            "Resource": [
                "${aws_s3_bucket.website.arn}",
                "${aws_s3_bucket.website.arn}/*",
                "${aws_s3_bucket.backup-website.arn}",
                "${aws_s3_bucket.backup-website.arn}/*"
            ]
        },
        {
            "Action": [
                "s3:ReplicateObject",
                "s3:ReplicateDelete",
                "s3:ReplicateTags",
                "s3:ObjectOwnerOverrideToBucketOwner"
            ],
            "Effect": "Allow",
            "Resource": [
                "${aws_s3_bucket.website.arn}/*",
                "${aws_s3_bucket.backup-website.arn}/*"
            ]
        }
    ]
}

POLICY
}

resource "aws_iam_role_policy_attachment" "s3_attach" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.s3_replication_exec_policy.arn
}
