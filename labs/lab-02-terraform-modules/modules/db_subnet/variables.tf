variable "owner_tag" {
  description = "Owner tag for resources (required by sandbox account)"
  type        = string
  default     = "jakub.ejnik"

  validation {
    condition     = length(var.owner_tag) > 0
    error_message = "Owner tag cannot be empty."
  }
}


variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}
