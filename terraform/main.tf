provider "aws" {
  region = "${var.website-bucket-region}"
  default_tags {
    tags = {
      Project = "portfolio-website"
    }
  }
}

provider "aws" {
  alias = "backup-website-region"
  region = "${var.backup-website-bucket-region}"
  default_tags {
    tags = {
      Project = "portfolio-website"
    }
  }
}

provider "aws" {
  alias = "cloudfront-certificate"
  region = "us-east-1"
  default_tags {
    tags = {
      Project = "portfolio-website"
    }
  }
}

