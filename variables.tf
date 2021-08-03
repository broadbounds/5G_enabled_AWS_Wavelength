variable "aws_region" {
  description = "The AWS region to create our infrastructure"
  default     = "us-east-2"
}

variable "ec2_type" {
  description = "The type of ec2 instances to create"
  default = "t2.micro"
}

variable "ec2_ami" {
  description = "The ami image to use for ec2 instances"
  default = "ami-077e31c4939f6a2f3"
}

variable "access_key" {
  type        = string
  default     = ""
}

variable "secret_key" {
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  default = "192.168.0.0/16"
}
