# cloudfront6.tf - WorkBC DEV2


resource "aws_cloudfront_distribution" "workbc-dev2" {

  count = var.cloudfront ? 1 : 0

  origin {
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols = [
      "TLSv1.2"]
    }

    domain_name = "workbc2.a55eb5-dev.stratus.cloud.gov.bc.ca"
    origin_id   = random_integer.cf_origin_id.result
	
	custom_header {
	  name = "X-Forwarded-Host"
	  value = "dev2.workbc.ca"
	}
	
  }
  
   origin {
	domain_name = "workbc-bucket.s3.ca-central-1.amazonaws.com"
	origin_id = "SDPR-Contents"
	origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

	origin {
	  domain_name = "workbc-bucket.s3.ca-central-1.amazonaws.com"
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
  comment         = "WorkBC.ca DEV2"

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
      restriction_type = "whitelist"
      locations = ["CA"]
    }
  }

  tags = var.common_tags
  
  aliases = ["dev2.workbc.ca"]

  viewer_certificate {
    acm_certificate_arn = "arn:aws:acm:us-east-1:396067939651:certificate/8422cb87-5c47-4dcf-86b3-04a93695fbca"
    ssl_support_method = "sni-only"
  }
  
  depends_on = [aws_cloudfront_cache_policy.custom, aws_cloudfront_origin_request_policy.custom]
  
}

