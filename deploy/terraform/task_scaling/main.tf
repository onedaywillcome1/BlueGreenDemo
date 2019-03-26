# A CloudWatch alarm that monitors cpu usage of containers for scaling up
resource "aws_cloudwatch_metric_alarm" "service_cpu_usage_high" {
  alarm_name              = "${var.service_name}-cpu-usage-above-${var.cpu_usage_high_threshold}"
  alarm_description       = "This alarm monitors ${var.service_name} cpu usage for scaling up"
  comparison_operator     = "GreaterThanOrEqualToThreshold"
  evaluation_periods      = "${var.cpu_usage_high_evaluation_periods}"
  metric_name             = "CPUUtilization"
  namespace               = "AWS/ECS"
  period                  = "${var.cpu_usage_high_period}"
  statistic               = "${var.statistic_type}"
  threshold               = "${var.cpu_usage_high_threshold}"
  alarm_actions           = ["${aws_appautoscaling_policy.cpu_usage_scale_up.arn}"]

  dimensions {
    ServiceName           = "${var.service_name}"
    ClusterName           = "${var.cluster_name}"
  }
}

# A CloudWatch alarm that monitors cpu usage of containers for scaling down
resource "aws_cloudwatch_metric_alarm" "service_cpu_usage_low" {
  alarm_name              = "${var.service_name}-cpu-usage-below-${var.cpu_usage_low_threshold}"
  alarm_description       = "This alarm monitors ${var.service_name} cpu usage for scaling down"
  comparison_operator     = "LessThanOrEqualToThreshold"
  evaluation_periods      = "${var.cpu_usage_low_evaluation_periods}"
  metric_name             = "CPUUtilization"
  namespace               = "AWS/ECS"
  period                  = "${var.cpu_usage_low_period}"
  statistic               = "${var.statistic_type}"
  threshold               = "${var.cpu_usage_low_threshold}"
  alarm_actions           = ["${aws_appautoscaling_policy.cpu_usage_scale_down.arn}"]

  dimensions {
    ServiceName           = "${var.service_name}"
    ClusterName           = "${var.cluster_name}"
  }
}

resource "aws_appautoscaling_policy" "cpu_usage_scale_up" {
  name                    = "${var.service_name}-cpu-scale-up-policy"
  resource_id             = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension      = "ecs:service:DesiredCount"
  service_namespace       = "ecs"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment = "${var.num_of_tasks_scale_up}"
    }
  }
  depends_on = ["aws_appautoscaling_target.appautoscaling_target"]
}

resource "aws_appautoscaling_policy" "cpu_usage_scale_down" {
  name                    = "${var.service_name}-cpu-scale-down-policy"
  resource_id             = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension      = "ecs:service:DesiredCount"
  service_namespace       = "ecs"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment = "${var.num_of_tasks_scale_down}"
    }
  }

  depends_on = ["aws_appautoscaling_target.appautoscaling_target"]
}

resource "aws_appautoscaling_target" "appautoscaling_target" {
  max_capacity       = "${var.max_task_number}"
  min_capacity       = "${var.min_task_number}"
  resource_id        = "service/${var.cluster_name}/${var.service_name}"
  role_arn           = "${aws_iam_role.service-role.arn}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_iam_role" "service-role" {
  name = "${var.service_name}-role"

  assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
 {
   "Effect": "Allow",
   "Principal": {
     "Service": ["ecs.amazonaws.com", "ec2.amazonaws.com", "autoscaling.amazonaws.com", "application-autoscaling.amazonaws.com","lambda.amazonaws.com"]
   },
   "Action": "sts:AssumeRole"
  }
  ]
 }
EOF
}

resource "aws_iam_role_policy" "service-policy" {
  name = "${var.service_name}-policy"
  role = "${aws_iam_role.service-role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:*",
        "ec2:*",
        "elasticloadbalancing:*",
        "ecr:*",
        "dynamodb:*",
        "cloudwatch:*",
        "s3:*",
        "rds:*",
        "sqs:*",
        "sns:*",
        "logs:*",
        "ssm:*",
        "autoscaling:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
