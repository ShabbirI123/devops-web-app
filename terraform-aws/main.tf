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


resource "aws_iam_role" "awsIAMRoleAppRunner" {
  name = "awsIAMRoleAppRunner"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "build.apprunner.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "myrolespolicy" {
  role       = aws_iam_role.awsIAMRoleAppRunner.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

resource "time_sleep" "waitrolecreate" {
  depends_on       = [aws_iam_role.awsIAMRoleAppRunner]
  create_duration  = "60s"
}

resource "aws_apprunner_service" "shabbir-app-runner" {
  depends_on   = [time_sleep.waitrolecreate]
  service_name = "shabbir-app-runner" # Replace with your desired service name
  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.awsIAMRoleAppRunner.arn
    }
    image_repository {
      image_identifier      = "245154219216.dkr.ecr.us-east-1.amazonaws.com/shabbir-repo:latest" # Replace with your ECR repository URL and image tag
      image_repository_type = "ECR"
      image_configuration {
        port = 80 # Replace with the desired port
      }
    }
  }
}
output "app_runner_url" {
  value = aws_apprunner_service.shabbir-app-runner.service_url
}
