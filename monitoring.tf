resource "aws_sns_topic" "approval_topic" {
  provider = aws.primary
  name     = "logicworks-pipeline-approvals"
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  provider            = aws.primary
  alarm_name          = "logicworks-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_actions       = [aws_sns_topic.approval_topic.arn]
}
