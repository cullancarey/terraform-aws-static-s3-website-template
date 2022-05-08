data "archive_file" "custom_header_lambda_zip" {
    type        = "zip"
    source_dir  = "./custom_header_lambda"
    output_path = "custom_header_lambda.zip"
}

resource "aws_iam_role" "iam_for_custom_header_lambda" {
  name = "rotate_custom_headers-assume-role-s3-static-website"
  path          = "/service-role/"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}

POLICY
}

resource "aws_lambda_function" "rotate_custom_header_lambda" {
  filename      = "custom_header_lambda.zip"
  function_name = "rotate_custom_headers-s3-static-website"
  role          = aws_iam_role.iam_for_custom_header_lambda.arn
  handler       = "rotate_custom_headers.lambda_handler"

  source_code_hash = "${data.archive_file.custom_header_lambda_zip.output_base64sha256}"
  environment {
    variables = {
      primary_bucket = "${var.root_domain_name}"
      backup_bucket = "www.${var.root_domain_name}"
    }
  }
  runtime = "python3.8"
  timeout = 300
  tags = {
    Name = "rotate_custom_headers-s3-static-website"
  }
}

resource "aws_iam_policy" "custom_header_lambda_iam_policy" {
  name = "rotate_custom_headers-LambdaBasicExecutionRole-s3-static-website"
  path = "/service-role/"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "cloudfront:GetDistributionConfig",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:cloudfront::${local.account_id}:distribution/${aws_cloudfront_distribution.website_distribution.id}",
                "arn:aws:logs:us-east-2:${local.account_id}:log-group:/aws/lambda/${aws_lambda_function.rotate_custom_header_lambda.function_name}:*"
            ]
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "s3:PutBucketPolicy",
                "cloudfront:UpdateDistribution",
                "logs:CreateLogGroup",
                "s3:GetBucketPolicy"
            ],
            "Resource": [
                "arn:aws:logs:us-east-2:${local.account_id}:*",
                "arn:aws:cloudfront::${local.account_id}:distribution/${aws_cloudfront_distribution.website_distribution.id}",
                "${aws_s3_bucket.website.arn}",
                "${aws_s3_bucket.backup-website.arn}"
            ]
        }
    ]
}

POLICY
}

resource "aws_cloudwatch_event_rule" "rotate_custom_headers" {
  name        = "rotate_custom_header-s3-static-website"
  schedule_expression = "${var.cron_schedule}"

}

resource "aws_cloudwatch_event_target" "custom_header_lambda_target" {
  rule      = aws_cloudwatch_event_rule.rotate_custom_headers.name
  arn       = aws_lambda_function.rotate_custom_header_lambda.arn
}