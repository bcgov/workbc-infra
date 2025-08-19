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

data "aws_security_group" "eks_node_sg" {
  id = aws_eks_cluster.workbc-cluster.vpc_config[0].cluster_security_group_id
}

resource "aws_security_group_rule" "allow_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = data.aws_security_group.eks_node_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_alb_target_group" "cdq" {
  name                 = "cdq-target-group"
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



