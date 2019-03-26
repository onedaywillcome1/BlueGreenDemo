output "task_definition_family" {
  value = "${aws_ecs_task_definition.task_definition.family}"
}