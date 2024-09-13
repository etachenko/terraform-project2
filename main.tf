provider "aws" {
  region = var.region
}

# Create a Security Group for Load Balancer allowing HTTPS access
resource "aws_security_group" "lb_sg" {
  name        = "lb_sg"
  description = "Allow HTTPS traffic to Load Balancer"
  vpc_id      = var.vpc_id

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

# Create a Security Group for EC2 instances allowing traffic from the LB
resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow HTTP traffic from Load Balancer to EC2"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create the Application Load Balancer
resource "aws_lb" "web_lb" {
  name               = "web-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = var.subnet_ids

  enable_deletion_protection = false
}

# Create a Target Group for the Load Balancer
resource "aws_lb_target_group" "web_tg" {
  name        = "web-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
  }
}

# Create a Listener for Load Balancer on HTTPS port 443
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"  # Choose the appropriate SSL policy

  certificate_arn   = var.certificate_arn  # SSL certificate from ACM

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# IAM Role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}

# Launch Configuration with user data to install Apache
resource "aws_launch_configuration" "web_launch_config" {
  name                = "web_launch_config"
  image_id            = var.ami_id
  instance_type       = var.instance_type
  security_groups     = [aws_security_group.web_sg.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>${var.welcome_message}</h1>" > /var/www/html/index.html
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group associated with Load Balancer's Target Group
resource "aws_autoscaling_group" "web_asg" {
  launch_configuration = aws_launch_configuration.web_launch_config.id
  min_size             = var.min_size
  max_size             = var.max_size
  desired_capacity     = var.desired_capacity
  vpc_zone_identifier  = var.subnet_ids

  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "webserver"
    propagate_at_launch = true
  }

  # Attach the Target Group
  target_group_arns = [aws_lb_target_group.web_tg.arn]
}

