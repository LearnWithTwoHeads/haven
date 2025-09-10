variable "hcloud_token" {
  sensitive = true # Requires terraform >= 0.14
}

variable "ssh_public_key" {
  type        = string
  description = "Public SSH key content (the .pub file content)"
  sensitive   = true
}
