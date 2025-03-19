provider "aws" {
  region = "ap-northeast-2"
  default_tags {
    tags = {
      Name = "seoyoung-terraform-practice4"
      Subject = "cloud-programming"
    }
  }
}

variable "vpc_main_cidr" {
  description = "VPC main CIDR block"
  default     = "10.1.0.0/23"
}

resource "aws_vpc" "my_vpc" {
  cidr_block           = var.vpc_main_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true
}

# a-zone 퍼블릭 서브넷 (public Subnet)
resource "aws_subnet" "pub_sub_1" {
  vpc_id                  = aws_vpc.my_vpc.id                           # VPC 연결
  cidr_block              = cidrsubnet(aws_vpc.my_vpc.cidr_block, 4, 0) # /27 서브넷 생성
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true # 공용 IP 자동 할당
}

# a-zone 프라이빗 서브넷 (Private Subnet)
resource "aws_subnet" "prv_sub_1" {
  vpc_id            = aws_vpc.my_vpc.id                           # VPC 연결
  cidr_block        = cidrsubnet(aws_vpc.my_vpc.cidr_block, 4, 2) # /27 서브넷 생성
  availability_zone = "ap-northeast-2a"
}

# b-zone 퍼블릭 서브넷 (public Subnet)
resource "aws_subnet" "pub_sub_2" {
  vpc_id                  = aws_vpc.my_vpc.id                           # VPC 연결
  cidr_block              = cidrsubnet(aws_vpc.my_vpc.cidr_block, 4, 1) # /27 서브넷 생성
  availability_zone       = "ap-northeast-2b"
  map_public_ip_on_launch = true # 공용 IP 자동 할당
}

# b-zone 프라이빗 서브넷 (Private Subnet)
resource "aws_subnet" "prv_sub_2" {
  vpc_id            = aws_vpc.my_vpc.id                           # VPC 연결
  cidr_block        = cidrsubnet(aws_vpc.my_vpc.cidr_block, 4, 3) # /27 서브넷 생성
  availability_zone = "ap-northeast-2b"
}

# 보조 CIDR 추가
resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.2.0.0/23"
}

# 인터넷 게이트웨이
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

# 퍼블릭 라우팅테이블
resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.my_vpc.id

  # 인터넷으로 나가는 기본 경로 설정 (0.0.0.0/0 → Internet Gateway)
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

# 프라이빗 라우팅테이블 1
resource "aws_route_table" "prv_st1" {
    vpc_id = aws_vpc.my_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat_gw_1.id
    }
}

# 프라이빗 라우팅테이블 2
resource "aws_route_table" "prv_st2" {
    vpc_id = aws_vpc.my_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat_gw_2.id
    }
}

# 라우팅 테이블과 서브넷 연결
resource "aws_route_table_association" "pub_rt_asso_1" {
    subnet_id = aws_subnet.pub_sub_1.id
    route_table_id = aws_route_table.pub_rt.id
}

resource "aws_route_table_association" "pub_rt_asso_2" {
    subnet_id = aws_subnet.pub_sub_2.id
    route_table_id = aws_route_table.pub_rt.id
}

resource "aws_route_table_association" "prv_rt_asso_1" {
    subnet_id = aws_subnet.prv_sub_1.id
    route_table_id = aws_route_table.prv_st1.id
}

resource "aws_route_table_association" "prv_rt_asso_2" {
    subnet_id = aws_subnet.prv_sub_2.id
    route_table_id = aws_route_table.prv_st2.id
}

# NAT GW에서 사욯할 EIP 생성
resource "aws_eip" "nat_eip1" {
    domain = "vpc"
}

# NAT GW에서 사욯할 EIP 생성 Elastic IP
resource "aws_eip" "nat_eip2" {
    domain = "vpc"
}

resource "aws_nat_gateway" "nat_gw_1" {
    allocation_id =  aws_eip.nat_eip1.id
    subnet_id = aws_subnet.pub_sub_1.id

    depends_on = [ aws_internet_gateway.my_igw ]
    # 명시적 의존성 선언으로 리소스 생성 순서 지정 가능 (IGW -> NAT)
}

resource "aws_nat_gateway" "nat_gw_2" {
    allocation_id =  aws_eip.nat_eip2.id
    subnet_id = aws_subnet.pub_sub_2.id

    depends_on = [ aws_internet_gateway.my_igw ]
    # 명시적 의존성 선언으로 리소스 생성 순서 지정 가능 (IGW -> NAT)
}

# 테라폼 자체 동작을 설정하는 terraform 블록
# terraform 블록에서는 변수 사용 불가
terraform {
  required_version = ">= 1.0.0, < 2.0.0"

    backend "s3" {
        bucket = "010307-seoyoung-practice4" # 상태 파일을 저장할 버킷의 이름
        key = "vpc/terraform.tfstate" # 버킷 내 경로
        region = "ap-northeast-2"
        encrypt = true # 암호화
        dynamodb_table = "010307-seoyoung-practice4" # 상태 잠금 활성화
    }
}



