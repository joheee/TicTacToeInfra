variable "name" {
  description = "Repository name."
  type        = string
}

variable "images_to_keep" {
  description = "Number of images kept by the lifecycle policy (at least 10 so rollbacks have a target)."
  type        = number
  default     = 10

  validation {
    condition     = var.images_to_keep >= 10
    error_message = "Keep at least 10 images so a rollback target always exists."
  }
}
