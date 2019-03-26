data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# CodeDeploy Configuration
resource "aws_codedeploy_app" "blue_green_app" {
  compute_platform = "ECS"
  name             = "${var.service_name}"

  depends_on = ["aws_ecs_service.ecs_service"]
}

resource "aws_codedeploy_deployment_group" "ecs_deployment_group" {
  app_name               = "${aws_codedeploy_app.blue_green_app.name}"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = "${var.service_name}-DeploymentGroup"
  service_role_arn       = "${aws_iam_role.code_deploy_ecs_role.arn}"

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "STOP_DEPLOYMENT"
      wait_time_in_minutes = "${var.wait_time}"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = "${var.wait_time}"
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = "${var.cluster_name}"
    service_name = "${var.service_name}"
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = ["${var.alb_blue_listener_arn}"]
      }

      target_group {
        name = "${aws_alb_target_group.ecs_blue_target_group.name}"
      }

      target_group {
        name = "${aws_alb_target_group.ecs_green_target_group.name}"
      }

      test_traffic_route {
        listener_arns = ["${var.alb_green_listener_arn}"]
      }
    }
  }

  depends_on = ["aws_alb_target_group.ecs_blue_target_group",
    "aws_alb_target_group.ecs_green_target_group",
    "aws_ecs_service.ecs_service"]
}

resource "null_resource" "run_deployment" {
  #This trigger will taint the resource automatically. So, don't run taint command
  triggers {
    build_number = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "bash ${path.module}/trigger_codedeploy.sh ${aws_codedeploy_app.blue_green_app.name} ${aws_codedeploy_deployment_group.ecs_deployment_group.deployment_group_name}"
  }
  depends_on = ["aws_codedeploy_deployment_group.ecs_deployment_group"]
}


resource "aws_iam_role" "code_deploy_ecs_role" {
  name                = "${var.service_name}-codeDeployBlueGreenECSRole"

  assume_role_policy  = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "codedeploy.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "code_deploy_ecs_policy" {
  name    = "${var.service_name}-codeDeployBlueGreenECSPolicy"
  role = "${aws_iam_role.code_deploy_ecs_role.id}"

  policy  = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ecs:*",
                "elasticloadbalancing:*",
                "iam:PassRole",
                "lambda:*",
                "cloudwatch:*",
                "sns:*",
                "s3:*",
                "codedeploy:*"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
          "Sid": "sid1",
          "Effect": "Allow",
          "Resource": [
                "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.service_name}-fargate_task_execution_role"
          ],
          "Action": "iam:PassRole"
        }
    ]
}
EOF
}
