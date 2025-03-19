provider "aws" {
  region = "ap-northeast-2"
  default_tags {
    tags = {
      Name = "010307"
    }
  }
}

# 보안 그룹 생성 (8080 포트 허용)
resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Allow HTTP access on port 8080"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 모든 IP에서 접근 가능 (보안 주의)
  }
}

# 인스턴스 생성
resource "aws_instance" "webserver" {
  ami           = "ami-058165de3b7202099"
  instance_type = "t2.micro"
  #   security_groups = [aws_security_group.web_sg.name]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.web_sg.id]

  # 사용자 데이터 스크립트 (EC2 실행 시 자동 실행됨)
  user_data = <<-EOF
    #!/bin/bash
    yum update && yum install -y busybox
    echo "Hello, World" > index.html
    nohup busybox httpd -f -p 8080 &
  EOF


  tags = {
    Name = "Terraform-WebServer"
  }
}