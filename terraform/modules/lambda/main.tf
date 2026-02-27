# IAM Role for Lambda
resource "aws_iam_role" "lambda_scheduler" {
  name = "${var.project_name}-${var.environment}-lambda-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-role"
  }
}

# IAM Policy — EC2 stop/start + CloudWatch logs
resource "aws_iam_role_policy" "lambda_scheduler" {
  name = "${var.project_name}-${var.environment}-lambda-policy"
  role = aws_iam_role.lambda_scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:StopInstances",
          "ec2:StartInstances",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeVolumes",
          "ec2:DeleteVolume"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda function — EC2 Scheduler
resource "aws_lambda_function" "ec2_scheduler" {
  filename         = var.ec2_scheduler_zip
  function_name    = "${var.project_name}-${var.environment}-ec2-scheduler"
  role             = aws_iam_role.lambda_scheduler.arn
  handler          = "ec2_scheduler.lambda_handler"
  runtime          = "python3.11"
  timeout          = 60
  source_code_hash = filebase64sha256(var.ec2_scheduler_zip)

  environment {
    variables = {
      ENVIRONMENT = var.environment
      REGION      = var.aws_region
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-scheduler"
  }
}

# Lambda function — EBS Cleanup
resource "aws_lambda_function" "ebs_cleanup" {
  filename         = var.ebs_cleanup_zip
  function_name    = "${var.project_name}-${var.environment}-ebs-cleanup"
  role             = aws_iam_role.lambda_scheduler.arn
  handler          = "ebs_cleanup.lambda_handler"
  runtime          = "python3.11"
  timeout          = 60
  source_code_hash = filebase64sha256(var.ebs_cleanup_zip)

  environment {
    variables = {
      ENVIRONMENT = var.environment
      REGION      = var.aws_region
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ebs-cleanup"
  }
}

# EventBridge rule — Stop EC2s at 7pm weekdays
resource "aws_cloudwatch_event_rule" "stop_ec2" {
  name                = "${var.project_name}-${var.environment}-stop-ec2"
  description         = "Stop dev EC2 instances at 7pm weekdays"
  schedule_expression = "cron(0 19 ? * MON-FRI *)"

  tags = {
    Name = "${var.project_name}-${var.environment}-stop-ec2-rule"
  }
}

# EventBridge rule — Start EC2s at 8am weekdays
resource "aws_cloudwatch_event_rule" "start_ec2" {
  name                = "${var.project_name}-${var.environment}-start-ec2"
  description         = "Start dev EC2 instances at 8am weekdays"
  schedule_expression = "cron(0 8 ? * MON-FRI *)"

  tags = {
    Name = "${var.project_name}-${var.environment}-start-ec2-rule"
  }
}

# EventBridge rule — EBS cleanup every Sunday
resource "aws_cloudwatch_event_rule" "ebs_cleanup" {
  name                = "${var.project_name}-${var.environment}-ebs-cleanup"
  description         = "Clean up unattached EBS volumes every Sunday"
  schedule_expression = "cron(0 0 ? * SUN *)"

  tags = {
    Name = "${var.project_name}-${var.environment}-ebs-cleanup-rule"
  }
}

# EventBridge targets
resource "aws_cloudwatch_event_target" "stop_ec2" {
  rule  = aws_cloudwatch_event_rule.stop_ec2.name
  arn   = aws_lambda_function.ec2_scheduler.arn
  input = jsonencode({ action = "stop" })
}

resource "aws_cloudwatch_event_target" "start_ec2" {
  rule  = aws_cloudwatch_event_rule.start_ec2.name
  arn   = aws_lambda_function.ec2_scheduler.arn
  input = jsonencode({ action = "start" })
}

resource "aws_cloudwatch_event_target" "ebs_cleanup" {
  rule = aws_cloudwatch_event_rule.ebs_cleanup.name
  arn  = aws_lambda_function.ebs_cleanup.arn
}

# Lambda permissions — allow EventBridge to invoke
resource "aws_lambda_permission" "stop_ec2" {
  statement_id  = "AllowEventBridgeStop"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_ec2.arn
}

resource "aws_lambda_permission" "start_ec2" {
  statement_id  = "AllowEventBridgeStart"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_ec2.arn
}

resource "aws_lambda_permission" "ebs_cleanup" {
  statement_id  = "AllowEventBridgeEBS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ebs_cleanup.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ebs_cleanup.arn
}
