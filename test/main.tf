provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_instance" "example" {
  ami           = "ami-062cddb9d94dcf95d"  # AWS AMI ID
  instance_type = "t2.micro"      # 인스턴스 타입

  tags = {
    Name = "seoyoung_terraform"
  }
}