#Load balancer params
variable "alb_name" {}
variable "alb_dns_name" {}
variable "alb_blue_listener_arn" {}
variable "alb_green_listener_arn" {}
variable "alb_sg_id" {}

#Dns params
variable "domain_name" {}
variable "domain_prefix" {}

#Service & Codedeploy params
variable "cluster_name" {}
variable "service_name" {}
variable "task_definition_name" {}
variable "wait_time" {}
variable "desired_task_number" {}
variable "docker_container_port" {}
