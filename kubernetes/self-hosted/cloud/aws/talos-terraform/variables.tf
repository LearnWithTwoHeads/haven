variable "vpc_cidr_range" {
  type        = string
  description = "CIDR range of the VPC"
  default     = "10.1.0.0/18"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  default     = ["10.1.0.0/22", "10.1.4.0/22"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private Subnet CIDR values"
  default     = ["10.1.8.0/22", "10.1.12.0/22"]
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones"
  default     = ["us-east-1a", "us-east-1b"]
}
