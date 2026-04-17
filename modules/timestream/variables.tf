variable "memory_retention_hours" {
  description = "Hours to retain data in Timestream memory store"
  type        = number
  default     = 24
}

variable "magnetic_retention_days" {
  description = "Days to retain data in Timestream magnetic store"
  type        = number
  default     = 365
}