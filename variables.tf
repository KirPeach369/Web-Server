variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet" {
  description = "Public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet" {
  description = "Private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "instance_type"{
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}







