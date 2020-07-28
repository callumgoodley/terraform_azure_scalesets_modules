variable "rgname" {
  description = "name of resource group for all env's"
}
variable "location" {
  description = "resource location"
}
variable "env" {
  description = "environment for tag"
}
variable "timezone" {
  description = "timezone for scale set"
}
variable "start_time" {
  description = "time for VM scale up to start each day"
}
variable "stop_time" {
  description = "time for VM scale down to stop each day"
}
