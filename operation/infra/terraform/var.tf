variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "key_name" {
  type        = string
  description = "Name of an existing EC2 key pair in this region"
}

