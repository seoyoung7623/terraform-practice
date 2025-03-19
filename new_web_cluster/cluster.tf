# resource "aws_security_group" "webserver_sg" {
#     name = "webserver-sg-student"
#     vpc_id = aws_vpc.my_vpc.id

#     ingress {
#         from_port = var.server_port
#         to_port = var.server_port
#         protocol = "tcp"
#         cidr_blocks = [aws_subnet.pub_sub_1.cidr_block, aws_subnet.pub_sub_2.cidr_block]
#     }

#     egress {
#         from_port = 0
#         to_port = 0
#         protocol = "-1"
#         cidr_blocks = ["0.0.0.0/0"]
#     }
# }

# # 시작 템플릿 작성
# resource "aws_launch_template" "webserver_template" {
#     image_id = "ami-027b635eef01a0325"
#     instance_type = "t3.micro"
#     vpc_security_group_ids = [aws_security_group.webserver_sg.id] # 보안그룹은 webserver_sg로 지정
    
#     user_data = base64encode(<<-EOF
#                 #!/bin/bash
#                 yum update -y
#                 yum install httpd -y
#                 systemctl start httpd
#                 systemctl enable httpd
#                 echo "<h1>Deployed via Terraform</h1>" > /var/www/html/index.html
#                 EOF
#     )
# }

# # 오토 스케일링 그룹 작성
# # 시작 템플릿 연결
# resource "aws_autoscaling_group" "webserver_asg" {
#     vpc_zone_identifier = [aws_subnet.pub_sub_1.id, aws_subnet.pub_sub_2.id] # 서브넷 아이디
#     # -> asg에 속한 인스턴스는 pub_sub_1, pub_sub_2 서브넷에 생성
#     target_group_arns = [aws_lb_target_group.target_asg.arn]
    
#     min_size = 2 # 최소 인스턴스 수
#     max_size = 3 # 최대 인스턴스 수
#     launch_template { # 시작 템플릿 연결
#         id = aws_launch_template.webserver_template.id # 시작 템플릿 아이디
#         version = "$Latest" # 최신 버전 사용
#     }
#     depends_on = [ aws_vpc.my_vpc, aws_subnet.pub_sub_1, aws_subnet.pub_sub_2 ] # 의존성 설정
#     # -> asg 생성 전에 vpc, subnet이 먼저 생성되어야 함
# }

# # 로드 밸런서 생성(ALB)
# resource "aws_security_group" "alb_sg" {
#     name = var.alb_security_group_name # 보안 그룹 이름
#     vpc_id = aws_vpc.my_vpc.id # VPC 아이디

#     ingress { # 인바운드 설정
#         from_port = var.server_port 
#         to_port = var.server_port 
#         protocol = "tcp" 
#         cidr_blocks = [var.my_ip] # 내 IP만 접근 가능
#     }

#     egress { # 아웃바운드 설정
#         from_port = 0
#         to_port = 0
#         protocol = "-1"
#         cidr_blocks = ["0.0.0.0/0"] # 모든 IP로 허용
#     }
# }

# resource "aws_lb" "webserver_alb" {
#     name = var.alb_name # ALB 이름
    
#     load_balancer_type = "application" # ALB 타입
#     subnets = [aws_subnet.pub_sub_1.id, aws_subnet.pub_sub_2.id] # 서브넷 아이디
#     security_groups = [aws_security_group.alb_sg.id] # 보안 그룹 아이디
# } # ALB 생성

# # 타겟 그룹 생성
# resource "aws_lb_target_group" "target_asg" {
#     name = var.alb_name # 타겟 그룹 이름
#     port = var.server_port # 포트
#     protocol = "HTTP"
#     vpc_id = aws_vpc.my_vpc.id # VPC 아이디

#     health_check { # 헬스 체크 설정
#         path = "/" # 경로
#         protocol = "HTTP" # 프로토콜
#         matcher = "200" # 상태 코드
#         interval = 15 # 체크 간격
#         timeout = 3  # 타임아웃
#         healthy_threshold = 2 # 정상 임계값
#         unhealthy_threshold = 2 # 비정상 임계값
#     }
# }

# # alb에서 특정 포트에 대한 트래픽을 라우팅하기 위한 리스너 생성
# resource "aws_lb_listener" "http" {
#     load_balancer_arn = aws_lb.webserver_alb.arn # ALB 아이디
#     port = var.server_port # 포트
#     protocol = "HTTP" # 프로토콜

#     default_action { # 기본 액션 설정
#         type = "forward" # 포워드
#         target_group_arn = aws_lb_target_group.target_asg.arn # 타겟 그룹 아이디
#     }
# }

# # 리스너 규칙 생성
# resource "aws_lb_listener_rule" "webserver_asg_rule" {
#     listener_arn = aws_lb_listener.http.arn # 리스너 아이디
#     priority = 100 # 우선순위(100이면 가장 먼저 실행)

#     condition { # 조건 설정
#         path_pattern { # 경로 패턴
#             values = ["*"] # 모든 경로
#         }
#     }

#     action { # 액션 설정
#       type = "forward" # 포워드
#       target_group_arn = aws_lb_target_group.target_asg.arn # 타겟 그룹 아이디
#     }
# }

# 보안그룹

resource "aws_security_group" "webserver_sg" {
  name   = "webserver-sg-studentN"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.pub_sub_1.cidr_block, aws_subnet.pub_sub_2.cidr_block]
  }
}

# Launch Template

# resource "aws_launch_template" "webserver_template" {  # 오타 수정
#   image_id      = "ami-058165de3b7202099"
#   instance_type = "t3.micro"  # instant_type → instance_type 수정
# }

resource "aws_launch_template" "webserver_template" {
  image_id      = "ami-024ea438ab0376a47"
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.webserver_sg.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum -y update && yum install -y busybox
    mkdir -p /var/www/html
    echo "Hello, World" > /var/www/html/index.html
    busybox httpd -f -p 80 -h /var/www/html &
  EOF
  )
}

# Auto Scaling Group

resource "aws_autoscaling_group" "webserver_asg" {
  vpc_zone_identifier = [aws_subnet.pub_sub_1.id, aws_subnet.pub_sub_2.id]
  
  # 대상그룹 지정
  target_group_arns = [aws_lb_target_group.target_asg.arn]  # 오타 수정
  health_check_type = "ELB"

  min_size = 2
  max_size = 3

  launch_template {
    id      = aws_launch_template.webserver_template.id
    version = "$Latest" # 항상 최신 버전 시작 템플릿 사용
  }

  depends_on = [aws_vpc.my_vpc, aws_subnet.pub_sub_1, aws_subnet.pub_sub_2]
}

# ALB

## ALB 보안그룹

resource "aws_security_group" "alb_sg" {
  name   = var.alb_security_group_name
  vpc_id = aws_vpc.my_vpc.id
  
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

## ALB 생성

resource "aws_lb" "webserver_alb" {
  name               = var.alb_name
  load_balancer_type = "application"
  subnets            = [aws_subnet.pub_sub_1.id, aws_subnet.pub_sub_2.id]  # 오타 수정
  security_groups    = [aws_security_group.alb_sg.id]
}

## Target Group

resource "aws_lb_target_group" "target_asg" {
  name     = var.alb_name
  port     = var.server_port  # 오타 수정
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id
  
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

## Listener

resource "aws_lb_listener" "http" {  # 오타 수정
  load_balancer_arn = aws_lb.webserver_alb.arn
  port              = var.server_port
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_asg.arn
  }
}

## Listener Rule

resource "aws_lb_listener_rule" "webserver_asg_rule" {  # 오타 수정
  listener_arn = aws_lb_listener.http.arn  # listner_arn → listener_arn 수정
  priority     = 100
 
  condition {
    path_pattern {
      values = ["*"]
    }
  }
 
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_asg.arn
  }
}