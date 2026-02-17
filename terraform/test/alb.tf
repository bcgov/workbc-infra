resource "aws_security_group" "alb_sg" {
  name        = "alb-https-sg"
  description = "Allow HTTPS inbound traffic"
  vpc_id      = data.aws_vpc.main.id

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
  port                 = 30083
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.main.id
  target_type          = "instance"
  deregistration_delay = 30

  health_check {
    healthy_threshold   = "5"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "5"
    path                = "/index.html"
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
  subnets            = data.aws_subnets.web.ids

  tags = {
    Public = "True"
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.default_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:ca-central-1:318574063652:certificate/c0af2406-ad4a-43a9-83a6-5c7d6acc0a65"

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


resource "aws_alb_target_group" "cdq" {
  name                 = "cdq-target-group"
  port                 = 30082
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.main.id
  target_type          = "instance"
  deregistration_delay = 30

  health_check {
    healthy_threshold   = "5"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "5"
    path                = "/index.html"
    unhealthy_threshold = "2"
  }
    
  lifecycle {
    create_before_destroy = true
  }

  tags = var.common_tags
}

resource "aws_lb_listener_rule" "host_based_weighted_routing2" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = 110

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.cdq.arn
  }

  condition {
    host_header {
      values = ["workbc-cdq.*"]
    }
  }
    
}

resource "aws_alb_target_group" "workbc" {
  name                 = "workbc-target-group"
  port                 = 30084
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.main.id
  target_type          = "instance"
  deregistration_delay = 30

  health_check {
    healthy_threshold   = "5"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "5"
    path                = "/index.html"
    unhealthy_threshold = "2"
  }
    
  lifecycle {
    create_before_destroy = true
  }

  tags = var.common_tags
}

resource "aws_lb_listener_rule" "host_based_weighted_routing3" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = 120

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.workbc.arn
  }

  condition {
    host_header {
      values = ["workbc.*"]
    }
  }
    
}

resource "aws_alb_target_group" "jb" {
  name                 = "jb-target-group"
  port                 = 30081
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.main.id
  target_type          = "instance"
  deregistration_delay = 30

  health_check {
    healthy_threshold   = "5"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "5"
    path                = "/health"
    unhealthy_threshold = "2"
#    port                = "8081"
  }
    
  lifecycle {
    create_before_destroy = true
  }

  tags = var.common_tags
}

resource "aws_lb_listener_rule" "host_based_weighted_routing4" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = 60

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.jb.arn
  }

  condition {
    host_header {
      values = ["workbc-jb.*"]
    }
  }
}

resource "aws_alb_target_group" "jbadm" {
  name                 = "jb-adm-target-group"
  port                 = 30080
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.main.id
  target_type          = "instance"
  deregistration_delay = 30

  health_check {
    healthy_threshold   = "5"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "5"
    path                = "/health"
    unhealthy_threshold = "2"
#    port                = "8080"
  }
    
  lifecycle {
    create_before_destroy = true
  }

  tags = var.common_tags
}

resource "aws_lb_listener_rule" "host_based_weighted_routing5" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = 50

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.jbadm.arn
  }

  condition {
    host_header {
      values = ["workbc-jb-adm.*"]
    }
  }

}





