variable "name" {
  description = "Name prefix, e.g. tictactoe-prod."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR of the VPC."
  type        = string
}

variable "app_port" {
  description = "Port the app is published on (HTTP, open to the internet)."
  type        = number
}
