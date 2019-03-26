resource "aws_ecs_cluster" "bg_cluster" {
  name = "${var.cluster_name}"
}

output "ecs_cluster_arn" {
  value = "${aws_ecs_cluster.bg_cluster.arn}"
}

output "ecs_cluster_id" {
  value = "${aws_ecs_cluster.bg_cluster.id}"
}


