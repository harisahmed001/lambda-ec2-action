resource "aws_iam_role" "wld_sts_lambda_role" {
  name = "wld-role-lambda-tf-${var.IDENTIFIER}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "wld_instance_action_policy" {
  name = "wld-policy-lambda-tf-${var.IDENTIFIER}"
  path        = "/"
  description = "policy allow ec2 to list and stop instances"

  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [{
      "Effect": "Allow",
      "Action": [
         "ec2:DescribeInstances",
         "ec2:StopInstances"
      ],
      "Resource": "*"
   }
   ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "wld_lambda_role_attach" {
  role       = aws_iam_role.wld_sts_lambda_role.name
  policy_arn = aws_iam_policy.wld_instance_action_policy.arn
}

data "archive_file" "wld_archive_code" {
  type        = "zip"
  source_dir  = "src/"
  output_path = "lambda_function_payload.zip"
}


###### If Using S3 ########
# data "aws_s3_bucket_object" "wld_data_s3_object" {
#   bucket = var.bucket_name
#   key    = var.lambda_payload
# }

resource "aws_lambda_function" "wld_lambda_ec2_function" {
  function_name     = "wld-lambda-tf-${var.IDENTIFIER}"
  role              = aws_iam_role.wld_sts_lambda_role.arn
  handler           = "lambda_function.lambda_handler"
  runtime           = "python3.8"
  filename          = var.lambda_payload
  source_code_hash  = filebase64sha256(var.lambda_payload)

  ###### If Using S3 ########
  #source_code_hash = data.aws_s3_bucket_object.wld_data_s3_object.body
  #s3_bucket         = var.bucket_name
  #s3_key            = var.lambda_payload

  timeout           = 30
  memory_size       = 128
  description       = "lambda function to stop non authorized ec2 instances and generate alert"

  depends_on = [
    aws_iam_role_policy_attachment.wld_lambda_role_attach
  ]

  environment {
    variables = {
      AMI_ID = var.AMI_ID
    }
  }
}


resource "aws_cloudwatch_event_rule" "wld_every_certain_minutes_cw_rule" {
    name = "every-certain-minutes"
    description = "Fires every certain minutes"
    schedule_expression = "cron(* * * * ? *)"
}

resource "aws_cloudwatch_event_target" "wld_execute_lambda_certain" {
    rule = aws_cloudwatch_event_rule.wld_every_certain_minutes_cw_rule.name
    target_id = "check"
    arn = aws_lambda_function.wld_lambda_ec2_function.arn
}

resource "aws_lambda_permission" "wld_allow_cw_exec_lambda" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.wld_lambda_ec2_function.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.wld_every_certain_minutes_cw_rule.arn
}

################ To Create SNS Topic #####################
# resource "aws_sns_topic" "wld_instance_action_topic" {
#   name = "wld-instance-action-topic"
# }
# resource "aws_sns_topic_subscription" "wld_send_message_on_alert" {
#   topic_arn = aws_sns_topic.wld_instance_action_topic.arn
#   protocol  = "sms"
#   endpoint = "+123456789"
# }
########################################################
