variable "public_key_path" {
  description = <<DESCRIPTION
Path to the SSH public key to be used for authentication.
Ensure this keypair is added to your local SSH agent so provisioners can
connect.

Example: ~/.ssh/terraform.pub
DESCRIPTION
}

variable "key_name" {
  description = "Desired name of AWS key pair"
}
variable "aws_vpc_cidr" {
}
variable "aws_external1_subnet_cidr" {
}
variable "aws_external2_subnet_cidr" {
}
variable "aws_webserver1_subnet_cidr" {
}
variable "aws_webserver2_subnet_cidr" {
}
variable "my_user_data" {
}
variable "ubuntu_user_data" {
}
variable "externaldnshost" {
}
variable "r53zone" {
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "eu-west-1"
}
variable "primary_az" {
  description = "primary AZ"
  default     = "eu-west-1a"
}
variable "secondary_az" {
  description = "secondary AZ"
  default     = "eu-west-1b"
}
# Check Point R80 BYOL
variable "aws_amis_vsec" {
  default = {
    eu-west-1 = "ami-4477f73d"
  }
}
# Ubuntu Image
variable "aws_amis_web" {
  default = {
    eu-west-1 = "ami-8fd760f6"
  }
}