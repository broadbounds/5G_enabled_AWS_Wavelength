variable "aws_region" {
  type = string
  default = "us-east-2"
}

variable "access_key" {
  type        = string
  default     = ""
}

variable "secret_key" {
  type        = string
  default     = ""
}

variable "public_key_name" {
  type        = string
  default     = "ssh_public_key"
}

variable "private_key_name" {
  type        = string
  default     = "ssh_private_key"
}

variable "key_path" {
  type        = string
  default     = "/var/lib/jenkins/.ssh/"
}

variable "WL_ZONE" {
  type        = string
  default     = "us-east-1-wl1-bos-wlz-1"
}

variable "NBG" {
  type        = string
  default     = "us-east-1-wl1-bos-wlz-1"
}

variable "INFERENCE_IMAGE_ID" {
  type        = string
  default     = "ami-029510cec6d69f121"
}

variable "API_IMAGE_ID" {
  type        = string
  default     = "ami-0ac80df6eff0e70b5"
}

variable "BASTION_IMAGE_ID" {
  type        = string
  default     = "ami-027b7646dafdbe9fa"
}

variable "KEY_NAME" {
  type        = string
  default     = "ssh_public_key"
}
