variable "server_port" {
  description = "Webserver's HTTP port"
  type        = number
  default     = 80
}

variable "my_ip" {
  description = "My public IP"
  type        = string
  default     = "0.0.0.0/0"
}

variable "alb_security_group_name" {
  description = "The name of the ALB's Security group"
  type        = string
  default     = "webserver-alb-sg-seoyoung"
}

variable "alb_name" {
  description = "The name of the ALB"
  type        = string
  default     = "webserver-alb-seoyoung"
}