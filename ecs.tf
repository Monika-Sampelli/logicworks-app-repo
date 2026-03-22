##############################
# ECS Cluster
##############################
resource "aws_ecs_cluster" "logicworks_cluster" {
  name = "logicworks-cluster"
}

##############################
# CloudWatch Logs
##############################
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/logicworks-app"
  retention_in_days = 7
}

##############################
# IAM Role for ECS Task Execution
##############################
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

##############################
# ECS Task Definition
##############################
resource "aws_ecs_task_definition" "app_task" {
  family                   = "logicworks-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "app"
    image     = "${aws_ecr_repository.app_repo.repository_url}:latest"
    essential = true
    portMappings = [{ 
      containerPort = 80, 
      hostPort      = 80,
      protocol      = "tcp"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/logicworks-app"
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

##############################
# ECS Service
##############################
resource "aws_ecs_service" "app_service" {
  name            = "app-service"
  cluster         = aws_ecs_cluster.logicworks_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.primary_subnet.id]
    security_groups  = [aws_security_group.app_sg.id]
    assign_public_ip = true
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}

