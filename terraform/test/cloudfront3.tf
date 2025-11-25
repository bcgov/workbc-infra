# cloudfront3.tf - WorkBC

resource "aws_cloudfront_origin_access_control" "oac" {
  name = "oac"
  description = "OAC Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior = "always"
  signing_protocol = "sigv4"
}

resource "aws_cloudfront_cache_policy" "custom" {
  name	      = "WorkBC-cache-policy"
  comment     = "WorkBC main site cache policy"
  default_ttl = 300
  max_ttl     = 31536000
  min_ttl     = 1
  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "whitelist"
      cookies {
        items = ["SSESS*"]
      }
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
       query_string_behavior = "all"
    }
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip = true 

  }
}

resource "aws_cloudfront_origin_request_policy" "custom" {
  name    = "WorkBC-origin-request-policy"
  comment = "Origin request settings to test CF tablet CF mobile CF desktop"
  cookies_config {
    cookie_behavior = "all"
  }
	headers_config {
		header_behavior = "allExcept"
		headers {
			items = ["Host"]
		}
	}
	query_strings_config {
		query_string_behavior = "none"
	}

}

resource "aws_cloudfront_distribution" "workbc-main" {

  count = var.cloudfront ? 1 : 0

  origin {
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols = [
      "TLSv1.2"]
    }

    domain_name = "workbc.a55eb5-test.stratus.cloud.gov.bc.ca"
    origin_id   = random_integer.cf_origin_id.result
	
	custom_header {
	  name = "X-Forwarded-Host"
	  value = "test.workbc.ca"
	}
	
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "WorkBC.ca"

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

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
	
    # SimpleCORS
    response_headers_policy_id = "60669652-455b-4ae9-85a4-c4c02393f86c"
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations = ["CA"]
    }
  }

  tags = var.common_tags
  
  aliases = ["test.workbc.ca"]

  viewer_certificate {
    acm_certificate_arn = "arn:aws:acm:us-east-1:318574063652:certificate/ff1d0af0-b95d-4e2c-80c9-c634ae2a0f51"
    ssl_support_method = "sni-only"
  }
}

