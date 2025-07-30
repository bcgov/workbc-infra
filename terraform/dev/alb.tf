resource "aws_security_group" "alb_sg" {
  name        = "alb-https-sg"
  description = "Allow HTTPS inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb_target_group" "cer" {
  name                 = "cer-target-group"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.main.id
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    healthy_threshold   = "5"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "5"
    path                = "/"
    unhealthy_threshold = "2"
  }
    
  lifecycle {
    create_before_destroy = true
  }

  tags = var.common_tags
}

resource "aws_lb" "default_alb" {
  name               = "default"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.app.ids
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:ca-central-1:396067939651:certificate/5818f61d-2848-48aa-9781-fdaf67be4bb9"

  default_action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_rule" "healthcheck_fixed_response" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = 10

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "OK"
      status_code  = "200"
    }
  }

  condition {
    path_pattern {
      values = ["/bcgovhealthcheck"]
    }
  }
}

resource "aws_lb_listener_rule" "host_based_weighted_routing" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.cer.arn
  }

  condition {
    host_header {
      values = ["workbc-cer.*"]
    }
  }
    
}
