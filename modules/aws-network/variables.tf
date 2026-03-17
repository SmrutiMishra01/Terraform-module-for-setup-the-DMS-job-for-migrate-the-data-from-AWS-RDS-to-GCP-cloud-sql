variable "vpc_cidr" {
  description = "CIDR block for the AWS VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "subnet_cidr_a" {
  description = "CIDR block for the first public subnet (AZ-a). Must be within vpc_cidr."
  type        = string
  default     = "10.10.1.0/24"
}

variable "subnet_cidr_b" {
  description = "CIDR block for the second public subnet (AZ-b). Required — AWS RDS subnet groups need subnets in at least 2 AZs."
  type        = string
  default     = "10.10.2.0/24"
}

variable "region" {
  description = "AWS region (e.g. ap-south-1). AZs are derived automatically as <region>a and <region>b."
  type        = string
}
