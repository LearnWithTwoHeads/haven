variable "vpc_cidr_range" {
  type        = string
  description = "CIDR range of the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  // These would contain different addresses because the first 24 bits are reserved for the network
  // and the last 8 bits are reserved for the host.
  // So the network address for both of these are `10.0.1.0` and `10.0.2.0`
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private Subnet CIDR values"
  default     = ["10.0.4.0/24", "10.0.5.0/24"]
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones"
  default     = ["us-east-1a", "us-east-1b"]
}

variable "ssh_key_name" {
  type        = string
  description = "Name for the SSH key pair in AWS"
  default     = "yke_key_pair"
}

variable "ssh_public_key" {
  type        = string
  description = "Public SSH key content (the .pub file content)"
  sensitive   = true
}
