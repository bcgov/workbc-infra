provider "aws" {
  alias  = "cloudfront_waf"
  region = "us-east-1" # This hardcoded global endpoint is only used for the WAF resources.
}

resource "aws_wafv2_ip_set" "cf_ipv4" {
  name               = "cf_ipv4"
  description        = "AWS CloudFront IP"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = ["10.0.0.0/8"]
}

resource "aws_wafv2_ip_set" "tester_ipv4" {
  provider           = aws.cloudfront_waf
  name               = "tester_ipv4"
  description        = "Tester IP"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
}

resource "aws_wafv2_ip_set" "tester_ipv6" {
  provider           = aws.cloudfront_waf
  name               = "tester_ipv6"
  description        = "Tester IP"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV6"
}

# Web ACL for CloudFront
resource "aws_wafv2_web_acl" "webacl_cf" {
  provider    = aws.cloudfront_waf
  name        = "WebACL-CF"
  description = "Web ACL for CloudFront"
  scope       = "CLOUDFRONT" # Must match the scope of the IP Set

  default_action {
    block {} # Block all traffic by default unless matched by a rule
  }

  rule {
    name     = "AllowTestersIPv4"
    priority = 1 # Lower numbers run first
    action {
      allow {} # Action to take when the IP matches (block, allow, count, etc.)
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.tester_ipv4.arn
        
        # Optional: Inspect forwarded IP headers if traffic passes through a proxy/CDN
        # forwarded_ip_config {
        #   header_name       = "X-Forwarded-For"
        #   fallback_behavior = "MATCH"
        # }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "WAFAllowTesterIPv4Metric"
      sampled_requests_enabled   = true
    }
  }
  
  rule {
    name     = "AllowTestersIPv6"
    priority = 2 # Lower numbers run first
    action {
      allow {} # Action to take when the IP matches (block, allow, count, etc.)
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.tester_ipv6.arn
        
        # Optional: Inspect forwarded IP headers if traffic passes through a proxy/CDN
        # forwarded_ip_config {
        #   header_name       = "X-Forwarded-For"
        #   fallback_behavior = "MATCH"
        # }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "WAFAllowTesterIPv6Metric"
      sampled_requests_enabled   = true
    }
  }

  # Overall visibility configuration for the Web ACL
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "WAFAllowTesterIPMetric"
    sampled_requests_enabled   = true
  }
}

# Web ACL for ALB
resource "aws_wafv2_web_acl" "webacl_alb" {
  name        = "WebACL-ALB"
  description = "Web ACL for Application Load Balancer"
  scope       = "REGIONAL" # Must match the scope of the IP Set

  default_action {
    block {} # Block all traffic by default unless matched by a rule
  }

 
  rule {
    name     = "AllowCloudFrontIPv4"
    priority = 1 # Lower numbers run first
    action {
      allow {} # Action to take when the IP matches (block, allow, count, etc.)
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.cf_ipv4.arn
        
        # Optional: Inspect forwarded IP headers if traffic passes through a proxy/CDN
        # forwarded_ip_config {
        #   header_name       = "X-Forwarded-For"
        #   fallback_behavior = "MATCH"
        # }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "WAFAllowCFIPv4Metric"
      sampled_requests_enabled   = true
    }
  }

  # Overall visibility configuration for the Web ACL
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "WAFAllowCFIPMetric"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "alb_association" {
  resource_arn = aws_lb.default_alb.arn             # The ARN of your ALB
  web_acl_arn  = aws_wafv2_web_acl.webacl_alb.arn # The ARN of your Regional Web ACL
}