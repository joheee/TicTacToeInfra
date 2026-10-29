variable "prefix" {
  description = "Parameter path without trailing slash, e.g. /tictactoe/prod."
  type        = string
}

variable "parameters" {
  description = "Parameter name => placeholder value. Real values are set outside Terraform."
  type        = map(string)
}
