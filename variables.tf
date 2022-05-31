variable "vpc_id" {
  type = string
  default= ""
}

variable "aws_access_key" {
   type = string
}

variable "aws_secret_key" {
   type = string
}

variable "name" {
 type = string
 default= "LaurentiuB"
}

variable  "ami_app" {
 type = string
 default = "ami-0015a39e4b7c0966f"
}

variable  "ssh_key" {
 type = string
 default = "New-Key"
}
