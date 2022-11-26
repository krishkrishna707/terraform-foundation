resource "aws_iam_role" "er" {
  name = "${var.roleName}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach" {
  for_each   = toset(local.awsManagedRoles)
  role       = aws_iam_role.er.name
  policy_arn = "arn:aws:iam::aws:policy/${each.value}"
}

resource "aws_iam_instance_profile" "aiip" {
  name = "${var.roleName}-ec2-role-profile"
  role = aws_iam_role.er.name
}


locals {
  awsManagedRoles = var.awsManagedRoles
}


resource "aws_instance" "demo" {
  ami                         = "ami-0b0dcb5067f052a63"
  instance_type               = "t2.micro"
  subnet_id                   = "subnet-6c54b206"
  vpc_security_group_ids      = ["sg-001c8cb9ff4242f72"]
  key_name                    = "dev-us-east-1-kp"
  iam_instance_profile        = aws_iam_instance_profile.aiip.name
  user_data     = <<EOF
		#!/usr/bin/env bash
        set -ex
		sudo yum update
		sudo yum install wget -y
		cd /tmp
		wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
		sudo dpkg -i amazon-ssm-agent.deb
		sudo systemctl start amazon-ssm-agent
		sudo systemctl enable amazon-ssm-agent
        sleep 10
        wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
        sudo rpm -U ./amazon-cloudwatch-agent.rpm
        sudo mkdir -p /usr/share/collectd/
        sudo touch /usr/share/collectd/types.db
        sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:Amazoncloudwatch-linux
	EOF
  tags = {
    Name = "instance_name"
  }
}
resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
     alarm_name                = "cpu-utilization"
     comparison_operator       = "GreaterThanOrEqualToThreshold"
     evaluation_periods        = "2"
     metric_name               = "CPUUtilization"
     namespace                 = "AWS/EC2"
     period                    = "120" #seconds
     statistic                 = "Average"
     threshold                 = "80"
     alarm_description         = "This metric monitors ec2 cpu utilization"
     insufficient_data_actions = []
dimensions = {
       InstanceId = aws_instance.demo.id
     }
}
 resource "aws_cloudwatch_metric_alarm" "ec2memory" {
    for_each                  = toset(local.instanceIdLists)
    alarm_name                = "${each.value}-memory-utilization"
    comparison_operator       = "GreaterThanOrEqualToThreshold"
    evaluation_periods        = "2"
    metric_name               = "mem_used_percent"
    namespace                 = "CWAgent"
    period                    = "120"
    statistic                 = "Average"
    threshold                 = "90"
    alarm_description         = "This metric monitors ${each.value} ec2 memory utilization"
    insufficient_data_actions = []
    dimensions = {
      InstanceId = each.value
    }
    alarm_actions = [aws_sns_topic.ast.arn]
    ok_actions    = [aws_sns_topic.ast.arn]
  }

variable "roleName" {
  default = "ssmcloud-instance"
}

variable "awsManagedRoles" {
  type        = list(string)
  default     = ["AmazonSSMFullAccess", "AmazonSSMManagedInstanceCore", "AmazonSSMPatchAssociation", "CloudWatchFullAccess”, “CloudWatchAgentAdminPolicy”, “CloudWatchAgentServerPolicy”]
  description = "List of StringList(s)"
}
