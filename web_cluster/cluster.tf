# EC2 보안그룹
resource "aws_security_group" "webserver_sg" {
    name = "webserver-sg-seoyoung"
    vpc_id = aws_vpc.my_vpc.id

    ingress{
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        cidr_blocks = [aws_subnet.pub_sub_1.cidr_block, aws_subnet.pub_sub_2.cidr_block]
    }
}

resource "aws_launch_template" "webserver_template" {
    image_id = "ami-027b635eef01a0325"
    instance_type = "t3.micro"
    vpc_security_group_ids = [aws_security_group.webserver_sg.id] # 보안그룹은 webserver_sg로 지정

    user_data = base64encode(<<-EOF
                #!/bin/bash
                yum update -y
                yum install httpd -y
                systemctl start httpd
                systemctl enable httpd
                echo "<h1>Deployed via Terraform</h1>" > /var/www/html/index.html
                EOF
    )
}


# resource "aws_launch_template" "webserver_template" {
#   image_id      = "ami-0eac65e0403505543"
#   instance_type = "t3.micro"
#   vpc_security_group_ids = [aws_security_group.webserver_sg.id]

#   user_data = base64encode(<<-EOF
#     #!/bin/bash
#     yum -y update && yum install -y busybox
#     mkdir -p /var/www/html
#     echo "Hello, World" > /var/www/html/index.html
#     busybox httpd -f -p 80 -h /var/www/html &
#   EOF
#   )
# }

# data "aws_subnets" "example" {
#   filter {
#     name = "vpc-id"
#     values = [aws_vpc.my_vpc]
#   }
# }

# 오토스케일링 설정
resource "aws_autoscaling_group" "webserver_asg" {
    vpc_zone_identifier = [aws_subnet.pub_sub_1.id,aws_subnet.pub_sub_2.id]

    min_size = 2
    max_size = 3

    target_group_arns = [aws_lb_target_group.target_asg.arn]
    # health_check_type = "ELB"

    launch_template {
      id = aws_launch_template.webserver_template.id
      version = "$Latest"
    }
    depends_on = [ aws_vpc.my_vpc, aws_subnet.pub_sub_1, aws_subnet.pub_sub_2]
}

# 로드밸런서 보안그룹
resource "aws_security_group" "alb_sg" {
    name = var.alb_security_group_name
    vpc_id = aws_vpc.my_vpc.id

    ingress{
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        cidr_blocks = [var.my_ip]
    }

    egress{
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# ALB생성
resource "aws_lb" "webserver_alb" {
    name = var.alb_name

    load_balancer_type = "application"
    subnets = [aws_subnet.pub_sub_1.id, aws_subnet.pub_sub_2.id]
    security_groups = [aws_security_group.alb_sg.id]
}

# 대상그룹 생성
resource "aws_lb_target_group" "target_asg" {
  name = var.alb_name
  port = var.server_port
  protocol = "HTTP"
  vpc_id = aws_vpc.my_vpc.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

# 리스너 생성
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.webserver_alb.arn
  port = var.server_port
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.target_asg.arn
  }
}

# 트래픽을 전달하는 규칙
resource "aws_lb_listener_rule" "webserver_asg_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.target_asg.arn
  }
}