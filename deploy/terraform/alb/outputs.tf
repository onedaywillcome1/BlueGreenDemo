output "alb_arn" {
  value = "${aws_alb.alb.arn}"
}

output "alb_sg_id" {
  value = "${aws_security_group.alb_sg.id}"
}

output "alb_dns_name" {
  value = "${aws_alb.alb.dns_name}"
}

output "alb_blue_listener_arn" {
  value = "${aws_alb_listener.alb_listener_80.arn}"
}

output "alb_green_listener_arn" {
  value = "${aws_alb_listener.alb_listener_8080.arn}"
}

output "alb_name" {
  value = "${aws_alb.alb.name}"
}