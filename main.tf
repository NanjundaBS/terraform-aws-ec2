###############################################################################
# Terraform AWS EC2 – Single File Configuration
###############################################################################

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

###############################################################################
# Variables
###############################################################################
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Existing AWS key pair name for SSH access"
  type        = string
}

variable "tags" {
  description = "Common tags for resources"
  type        = map(string)
  default     = {
    Project = "terraform-aws-ec2"
    Owner   = "YourName"
  }
}

###############################################################################
# Provider
###############################################################################
provider "aws" {
  region = var.aws_region
}

###############################################################################
# Data Sources
###############################################################################
data "aws_vpc" "default" {
  default = true
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

###############################################################################
# Resources
###############################################################################
resource "aws_security_group" "ec2_sg" {
  name        = "ec2_sg"
  description = "Allow SSH inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_instance" "ec2_example" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tags = merge(var.tags, { Name = "terraform-ec2" })
}

###############################################################################
# Outputs
###############################################################################
output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.ec2_example.public_ip
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.ec2_example.id
}
