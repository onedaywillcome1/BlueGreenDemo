data "aws_vpc" "vpc" {
  tags = {
    Key = "BlueGreenDemo"
  }
}

data "aws_subnet_ids" "private" {
  vpc_id = "${data.aws_vpc.vpc.id}"

  tags = {
    Type = "Private"
  }
}

# FARGATE Configuration
resource "aws_ecs_service" "ecs_service" {
  launch_type = "FARGATE"

  name            = "${var.service_name}"
  task_definition = "${var.task_definition_name}"
  cluster         = "${var.cluster_name}"
  desired_count   = "${var.desired_task_number}"

  network_configuration {
    security_groups = ["${aws_security_group.fargate_sg.id}"]
    subnets         = ["${data.aws_subnet_ids.private.ids}"]
    assign_public_ip = false
  }

  load_balancer {
    container_name   = "${var.service_name}"
    container_port   = "${var.docker_container_port}"
    target_group_arn = "${aws_alb_target_group.ecs_blue_target_group.arn}"
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  lifecycle {
    ignore_changes = ["task_definition","load_balancer"]
  }

  depends_on = ["aws_ecs_cluster.bg_cluster","aws_alb_target_group.ecs_blue_target_group","aws_alb_target_group.ecs_green_target_group"]
}

resource "aws_security_group" "fargate_sg" {
  name        = "${var.service_name}-fargate-sg"
  description = "Allows all traffic for internal traffic"
  vpc_id      = "${data.aws_vpc.vpc.id}"

  ingress {
    from_port   = 32768
    to_port     = 65535
    protocol    = "tcp"
    security_groups = ["${var.alb_sg_id}"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = ["${var.alb_sg_id}"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = ["${var.alb_sg_id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_alb_target_group" "ecs_blue_target_group" {
  name      = "${var.service_name}-Blue-TG"
  port      = "${var.docker_container_port}"
  protocol  = "HTTP"
  vpc_id    = "${data.aws_vpc.vpc.id}"
  target_type = "ip"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = "60"
    timeout             = "30"
    unhealthy_threshold = "3"
    healthy_threshold   = "3"
  }

  tags {
    Name = "${var.service_name}-Blue-TG"
    alb_name= "${var.alb_name}"
  }

}

resource "aws_alb_target_group" "ecs_green_target_group" {
  name      = "${var.service_name}-Green-TG"
  port      = "${var.docker_container_port}"
  protocol  = "HTTP"
  vpc_id    = "${data.aws_vpc.vpc.id}"
  target_type = "ip"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = "60"
    timeout             = "30"
    unhealthy_threshold = "3"
    healthy_threshold   = "3"
  }

  tags {
    Name = "${var.service_name}-Green-TG"
    alb_name= "${var.alb_name}"
  }
}

resource "aws_alb_listener_rule" "ecs_alb_blue_listener_rule" {
  listener_arn = "${var.alb_blue_listener_arn}"

  "action" {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.ecs_blue_target_group.arn}"
  }

  "condition" {
    field   = "host-header"
    values  = ["${lower(var.domain_prefix)}.${var.domain_name}"]
  }

  depends_on = ["aws_alb_target_group.ecs_blue_target_group"]

  lifecycle {
    ignore_changes = ["*"]
  }
}

resource "aws_alb_listener_rule" "ecs_alb_green_listener_rule" {
  listener_arn = "${var.alb_green_listener_arn}"

  "action" {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.ecs_green_target_group.arn}"
  }

  "condition" {
    field   = "host-header"
    values  = ["${lower(var.domain_prefix)}.${var.domain_name}"]
  }

  depends_on = ["aws_alb_target_group.ecs_green_target_group"]

  lifecycle {
    ignore_changes = ["*"]
  }
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name = "${var.service_name}-LogGroup"
}


output "cluster_name" {
  value = "${aws_ecs_service.ecs_service.cluster}"
}

output "service_name" {
  value = "${aws_ecs_service.ecs_service.name}"
}