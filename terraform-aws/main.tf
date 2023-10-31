terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_ecs_cluster" "webApp" {
  name = "webApp-cluster"
}

resource "aws_ecs_task_definition" "webApp" {
  family                   = "webApp-family"
  container_definitions    = <<DEFINITION
[
  {
    "name": "webApp-container",
    "image": "shabbirislam/devops-web-app:11",
    "memory": 512,
    "cpu": 256,
    "essential": true,
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ]
  }
]
DEFINITION
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
}

resource "aws_ecs_service" "webApp" {
  name            = "webApp-service"
  cluster         = aws_ecs_cluster.webApp.id
  task_definition = aws_ecs_task_definition.webApp.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.webApp.id]
    security_groups  = [aws_security_group.webApp.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.webApp.arn
    container_name   = "webApp-container"
    container_port   = 80
  }
}

resource "aws_vpc" "webApp" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "webApp" {
  vpc_id            = aws_vpc.webApp.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "webApp2" {
  vpc_id            = aws_vpc.webApp.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_security_group" "webApp" {
  vpc_id = aws_vpc.webApp.id
}

resource "aws_alb" "webApp" {
  name            = "webApp-alb"
  subnets         = [aws_subnet.webApp.id, aws_subnet.webApp2.id]
  security_groups = [aws_security_group.webApp.id]
}

resource "aws_lb_target_group" "webApp" {
  name        = "webApp-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.webApp.id
  target_type = "ip"
}
