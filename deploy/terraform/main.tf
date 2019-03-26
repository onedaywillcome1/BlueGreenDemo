terraform {
  backend "s3" {}
}

provider "aws" {
  region = "${var.region}"
  version = "2.2.0"
}


module "alb" {
  source         = "alb"
  alb_name       = "${var.alb_name}"
}

module "task_definition" {
  source = "task_definition"
  cluster_name            = "${var.cluster_name}"
  service_name            = "${var.service_name}"
  image_url               = "${var.image_url}"
  cpu                     = "${var.cpu}"
  memoryHardLimit         = "${var.memoryHardLimit}"
  memorySoftLimit         = "${var.memorySoftLimit}"
  docker_container_port   = "${var.docker_container_port}"
}

module "fargate_codedeploy" {
  source                  = "fargate_codedeploy"
  alb_sg_id               = "${module.alb.alb_sg_id}"
  cluster_name            = "${var.cluster_name}"
  service_name            = "${var.service_name}"
  task_definition_name    = "${module.task_definition.task_definition_family}"
  desired_task_number     = "${var.desired_task_number}"
  docker_container_port   = "${var.docker_container_port}"
  wait_time               = "${var.wait_time}"
  domain_name             = "${var.domain_name}"
  domain_prefix           = "${var.domain_prefix}"
  alb_name                = "${module.alb.alb_name}"
  alb_dns_name            = "${module.alb.alb_dns_name}"
  alb_blue_listener_arn   = "${module.alb.alb_blue_listener_arn}"
  alb_green_listener_arn  = "${module.alb.alb_green_listener_arn}"
}

module "task_scaling" {
  source = "task_scaling"
  cluster_name = "${module.fargate_codedeploy.cluster_name}"
  service_name = "${module.fargate_codedeploy.service_name}"
  max_task_number = "${var.max_task_number}"
  min_task_number = "${var.min_task_number}"
}
