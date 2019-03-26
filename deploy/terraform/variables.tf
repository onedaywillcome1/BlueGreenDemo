variable "region" {
  default = "us-east-1"
}

variable "alb_name" {
  default = "BlueGreenDemo"
}

variable "service_name" {
  default = "BlueGreenDemo"
}

variable "cluster_name" {
  default = "BlueGreenDemo"
}

variable "domain_prefix" {
  default = "mybgapp"
}

variable "wait_time" {
  default = 5
}

variable "desired_task_number" {
  default = 1
}

variable "docker_container_port" {
  default = 8080
}

variable "cpu" {
  default = 256
}

variable "memoryHardLimit" {
  default = 1024
}

variable "memorySoftLimit" {
  default = 950
}

variable "max_task_number" {
  default = 2
}

variable "min_task_number" {
  default = 1
}

variable "image_url" {}
variable "domain_name" {}

