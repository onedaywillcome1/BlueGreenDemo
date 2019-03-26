variable "cluster_name" {}
variable "service_name" {}
variable "max_task_number" {}
variable "min_task_number" {}
variable "cpu_usage_high_threshold" {
  default = 80
}
variable "cpu_usage_high_evaluation_periods" {
  default = 5
}
variable "cpu_usage_high_period" {
  default = 300
}
variable "cpu_usage_low_threshold" {
  default = 10
}
variable "cpu_usage_low_evaluation_periods" {
  default = 3
}
variable "cpu_usage_low_period" {
  default = 300
}
variable "statistic_type" {
  default = "Average"
}
variable "num_of_tasks_scale_up" {
  default = 1
}
variable "num_of_tasks_scale_down" {
  default = -1
}