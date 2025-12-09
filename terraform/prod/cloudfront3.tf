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

    domain_name = "workbc.a55eb5-prod.stratus.cloud.gov.bc.ca"
    origin_id   = random_integer.cf_origin_id.result
	
	custom_header {
	  name = "X-Forwarded-Host"
	  value = "www.workbc.ca"
	}
	custom_header {
	  name = "WorkBC-Source"
      value = var.source_token
	}
  }
  
   origin {
	domain_name = aws_s3_bucket.workbc_s3.bucket_regional_domain_name
#	domain_name = "workbc-bucket.s3.ca-central-1.amazonaws.com"
	origin_id = "SDPR-Contents"
	origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

	origin {
	  domain_name = aws_s3_bucket.workbc_s3.bucket_regional_domain_name
#	  domain_name = "workbc-bucket.s3.ca-central-1.amazonaws.com"
	  origin_id = "Maintenance-Window"
	  origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
	}
	
	custom_error_response {
      error_code = 403
      response_page_path = "/indexmaintenance.html"
      response_code = 200
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
	cache_policy_id = aws_cloudfront_cache_policy.custom.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.custom.id


    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
	
    # SimpleCORS
    response_headers_policy_id = "60669652-455b-4ae9-85a4-c4c02393f86c"
		#This cloudfront function redirects aws.workbc.ca to dev.workbc.ca -- 301
#    function_association {
#      event_type   = "viewer-request"
#      function_arn = "arn:aws:cloudfront::873424993519:function/pearldevcfredirect"
#    }
  }
  
  ordered_cache_behavior {
        path_pattern = "/getmedia/*"
        allowed_methods = [
        "DELETE",
        "GET",
        "HEAD",
        "OPTIONS",
        "PATCH",
        "POST",
        "PUT"]
        cached_methods = ["GET", "HEAD"]
	target_origin_id = "SDPR-Contents"
	cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
	viewer_protocol_policy = "redirect-to-https"
  }
  
    ordered_cache_behavior {
        path_pattern = "/WorkBC-Template/*"
        allowed_methods = [
        "DELETE",
        "GET",
        "HEAD",
        "OPTIONS",
        "PATCH",
        "POST",
        "PUT"]
        cached_methods = ["GET", "HEAD"]
        target_origin_id = "SDPR-Contents"
	cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
	viewer_protocol_policy = "redirect-to-https"
  }

    ordered_cache_behavior {
        path_pattern = "/indexmaintenance.html"
        allowed_methods = [
        "DELETE",
        "GET",
        "HEAD",
        "OPTIONS",
        "PATCH",
        "POST",
        "PUT"]
        cached_methods = ["GET", "HEAD"]
        target_origin_id = "SDPR-Contents"
	cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
	viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations = []
    }
  }

  tags = var.common_tags
  
  aliases = ["www.workbc.ca"]

  viewer_certificate {
    acm_certificate_arn = "arn:aws:acm:us-east-1:201730504816:certificate/34b94c2f-2826-4ec6-8883-423ecc3364dd"
    ssl_support_method = "sni-only"
  }
  
  depends_on = [aws_cloudfront_cache_policy.custom, aws_cloudfront_origin_request_policy.custom]
}

