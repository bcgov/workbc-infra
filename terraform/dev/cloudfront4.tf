# cloudfront for JobBoard

resource "aws_cloudfront_origin_request_policy" "custom2" {
  name = "Jobboard-origin-request-policy"

  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["Origin", "Authorization"]
    }
  }

  cookies_config {
    cookie_behavior = "all"
  }

  query_strings_config {
    query_string_behavior = "all"
  }
}

resource "aws_cloudfront_distribution" "workbc-jb" {

  count = var.cloudfront ? 1 : 0

  origin {
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols = [
      "TLSv1.2"]
    }

    domain_name = "workbc-jb.a55eb5-dev.stratus.cloud.gov.bc.ca"
    origin_id   = random_integer.cf_origin_id.result
	
	custom_header {
	  name = "X-Forwarded-Host"
	  value = "dev-api-jobboard.workbc.ca"
	}
	
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "JobBoard API"

  default_cache_behavior {
    allowed_methods = [
      "DELETE",
      "GET",
      "HEAD",
      "OPTIONS",
      "PATCH",
      "POST",
    "PUT"]
    cached_methods = ["GET", "HEAD"]

    target_origin_id = random_integer.cf_origin_id.result
	
    forwarded_values {
      query_string = true
      headers = ["Origin", "Authorization"]

      cookies {
        forward = "all"
      }
    }
#	cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
	
    # Custom CORS
    response_headers_policy_id = aws_cloudfront_response_headers_policy.cors_api.id
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  tags = var.common_tags
  
  aliases = ["dev-api-jobboard.workbc.ca"]

  viewer_certificate {
    acm_certificate_arn = "arn:aws:acm:us-east-1:396067939651:certificate/8422cb87-5c47-4dcf-86b3-04a93695fbca"
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method = "sni-only"
  }
}

resource "aws_cloudfront_response_headers_policy" "cors_api" {
  name = "cors-api-jobboard"

  cors_config {
    access_control_allow_credentials = true

    access_control_allow_origins {
      items = ["https://dev.workbc.ca", "https://dev2.workbc.ca", "http://localhost", "http://localhost:8080", "http://workbc.docker.localhost:8000"]
    }

    access_control_allow_methods {
      items = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
    }

    access_control_allow_headers {
      items = [
	  "Content-Type",
	  "Authorization",
	  "Cache-Control",
	  "Expires",
	  "Pragma",
	  "If-Modified-Since"
	  ]
    }

    origin_override = true
	access_control_max_age_sec = "86400"
  }
}
