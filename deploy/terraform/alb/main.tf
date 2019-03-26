data "aws_vpc" "vpc" {
  tags = {
    Key = "BlueGreenDemo"
  }
}

data "aws_subnet_ids" "public" {
  vpc_id = "${data.aws_vpc.vpc.id}"

  tags = {
    Type = "Public"
  }
}

resource "aws_alb" "alb" {
  name            = "${var.alb_name}-ALB"
  internal        = false
  security_groups = ["${aws_security_group.alb_sg.id}"]
  subnets         = ["${data.aws_subnet_ids.public.ids}"]
  tags {
    Name          = "${var.alb_name}-alb"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_alb_target_group" "alb_tg_80" {
  name     = "${var.alb_name}-TG-80"
  port     = "80"
  protocol = "HTTP"
  vpc_id   = "${data.aws_vpc.vpc.id}"

  tags {
    Name   = "${var.alb_name}-TG-80"
  }
  depends_on = ["aws_alb.alb"]
}

resource "aws_alb_target_group" "alb_tg_8080" {
  name     = "${var.alb_name}-TG-8080"
  port     = "80"
  protocol = "HTTP"
  vpc_id   = "${data.aws_vpc.vpc.id}"

  tags {
    Name   = "${var.alb_name}-TG-8080"
  }
  depends_on = ["aws_alb.alb"]
}

resource "aws_alb_listener" "alb_listener_80" {
  load_balancer_arn = "${aws_alb.alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action  {
    target_group_arn = "${aws_alb_target_group.alb_tg_80.arn}"
    type             = "forward"
  }
}

resource "aws_alb_listener" "alb_listener_8080" {
  load_balancer_arn = "${aws_alb.alb.arn}"
  port              = "8080"
  protocol          = "HTTP"

  default_action  {
    target_group_arn = "${aws_alb_target_group.alb_tg_8080.arn}"
    type             = "forward"
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.alb_name}-alb-sg"
  description = "Allows ports 80 and 8080 for alb"
  vpc_id      = "${data.aws_vpc.vpc.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

