data "aws_region" "current" {}
data "aws_caller_identity" "current"{}

resource "aws_ecs_task_definition" "task_definition" {
  family                    = "${var.service_name}"
  requires_compatibilities  = ["FARGATE"]
  network_mode              = "awsvpc"
  execution_role_arn        = "${aws_iam_role.fargate_task_execution_role.arn}"
  cpu                       = "${var.cpu}"
  memory                    = "${var.memoryHardLimit}"

  container_definitions     = <<EOF
    [
      {
        "name": "${var.service_name}",
        "image": "${var.image_url}",
        "memory": ${var.memoryHardLimit},
        "memoryReservation":  ${var.memorySoftLimit},
        "cpu": ${var.cpu},
        "essential": true,
        "portMappings": [
          {
            "containerPort": ${var.docker_container_port},
            "hostPort": ${var.docker_container_port}
          }
        ],
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-group": "${var.service_name}-LogGroup",
                "awslogs-region": "${data.aws_region.current.name}",
                "awslogs-stream-prefix": "${var.service_name}-LogGroup-stream"
            }
        }
      }
]
EOF
}

resource "aws_s3_bucket_object" "codedeploy_appspec" {
  bucket = "tf-state-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  key    = "appspec.json"
  content = <<EOF
  {
  "version": 1,
  "Resources": [
    {
      "TargetService": {
        "Type": "AWS::ECS::Service",
        "Properties": {
          "TaskDefinition": "${aws_ecs_task_definition.task_definition.arn}",
          "LoadBalancerInfo": {
            "ContainerName": "${var.service_name}",
            "ContainerPort": ${var.docker_container_port}
          }
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role" "fargate_task_execution_role" {
  name                = "${var.service_name}-fargate_task_execution_role"
  assume_role_policy  = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ecs-tasks.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "code_deploy_ecs_policy" {
  name    = "${var.service_name}-fargate_task_execution_policy"
  role = "${aws_iam_role.fargate_task_execution_role.id}"

  policy  = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
          "Sid": "sid1",
          "Effect": "Allow",
          "Action": [
                "ssm:GetParameters"
          ],
          "Resource": [
                "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/*"
          ]
        }
    ]
}
EOF
}




