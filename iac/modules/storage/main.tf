# ── Storage Module ────────────────────────────────────────────────────────────
# Creates an S3 bucket configured for static website hosting.
# Block Public Access is disabled only to allow the public bucket policy —
# acceptable for a static demo site with no sensitive data.
# In production: use CloudFront + OAC and keep BPA fully enabled.

resource "aws_s3_bucket" "website" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = {
    Name    = var.bucket_name
    Project = var.name
    Owner   = var.owner
  }
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  depends_on = [aws_s3_bucket_public_access_block.website]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadForWebsite"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  content_type = "text/html"

  content = <<-HTML
    <!DOCTYPE html>
    <html>
    <head><title>Hello World from S3</title></head>
    <body>
      <h1>Hello World from S3</h1>
      <p>Bucket: ${var.bucket_name}</p>
      <p>Region: ${var.region}</p>
    </body>
    </html>
  HTML
}

resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.website.id
  key          = "error.html"
  content_type = "text/html"

  content = <<-HTML
    <!DOCTYPE html>
    <html>
    <head><title>Error</title></head>
    <body><h1>404 - Page Not Found</h1></body>
    </html>
  HTML
}
