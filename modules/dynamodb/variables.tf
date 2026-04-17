variable "ttl_days" {
  description = "Number of days before vehicle records expire from DynamoDB"
  type        = number
  default     = 7
}