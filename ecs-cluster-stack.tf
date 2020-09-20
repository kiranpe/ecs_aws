provider "aws" {
  region  = "us-east-2"
  profile = "Terrafrm"
}

#Security Group
####################

resource "aws_security_group" "efs_sec_group" {
  name   = "efs_security_group"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "Security group for integration services mount target"
  }

  tags = {
    Name            = "${var.EFSStackName}"
    APMID           = "${var.APMID}"
    BillingApprover = "${var.BillingApprover}"
    BusinessSegment = "${var.BusinessSegment}"
    BusinessTower   = "${var.BusinessTower}"
    CreatedBy       = "${var.CreatedBy}"
    Environment     = "${var.Environment}"
    FMC             = "${var.FMC}"
    Service         = "${var.Service}"
    SupportGroup    = "${var.SupportGroup}"
  }
}


resource "aws_security_group" "ecs_sec_group" {
  name   = "ecs_security_group"
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = var.ports_cidr

    iterator = cidr_block

    content {
      from_port   = 22
      to_port     = 22
      cidr_blocks = [cidr_block.value]
      protocol    = "tcp"

    }
  }

  tags = {
    Name            = "${var.ECSStackName}"
    APMID           = "${var.APMID}"
    BillingApprover = "${var.BillingApprover}"
    BusinessSegment = "${var.BusinessSegment}"
    BusinessTower   = "${var.BusinessTower}"
    CreatedBy       = "${var.CreatedBy}"
    Environment     = "${var.Environment}"
    FMC             = "${var.FMC}"
    Service         = "${var.Service}"
    SupportGroup    = "${var.SupportGroup}"
  }
}

#######################
# Launch configuration
#######################

data "template_file" "local_data" {
  template = file("${path.module}/user_data.sh")

  vars = {
    region      = var.region
    stackname   = var.stackname
    environment = var.Environment
    stackid     = var.APMID
    subnet_0  = "10.175.10.88"
    subnet_1  = "10.173.200.208"
    subnet_2  = "10.172.200.58"
    subnet_3  = "10.175.11.208"
    subnet_4  = "10.173.201.79"
    subnet_5  = "10.172.201.103"
    subnet_6  = "10.175.12.245"
    subnet_7  = "10.173.202.253"
    subnet_8  = "10.172.202.9"
    subnet_9 = "10.175.200.141"
    subnet_10 = "10.175.201.59"
    subnet_11 = "10.175.202.80"
    #    ecs_config        = var.ecs_config
    #    ecs_logging       = var.ecs_logging
    asg_group    = var.asg_grp
    cluster_name = var.cluster_name
    custom_userdata   = var.custom_userdata
    efs_mountpoint    = var.efs_mountpoint
  }
}

resource "aws_launch_configuration" "ecs_launch_configuration" {
  count = var.create_lc ? 1 : 0

  name                        = var.lc_name
  image_id                    = var.image_id[var.region]
  instance_type               = var.instance_type
  iam_instance_profile        = var.iam_instance_profile
  key_name                    = var.key_name
  security_groups             = [aws_security_group.efs_sec_group.id, aws_security_group.efs_sec_group.id]
  associate_public_ip_address = var.associate_public_ip_address
  user_data                   = data.template_file.local_data.rendered
  user_data_base64            = var.user_data_base64
  enable_monitoring           = var.enable_monitoring
  spot_price                  = var.spot_price
  ebs_optimized               = var.ebs_optimized

  dynamic "ebs_block_device" {
    for_each = var.ebs_block_device
    content {
      delete_on_termination = lookup(ebs_block_device.value, "delete_on_termination", null)
      device_name           = ebs_block_device.value.device_name
      encrypted             = lookup(ebs_block_device.value, "encrypted", null)
      iops                  = lookup(ebs_block_device.value, "iops", null)
      no_device             = lookup(ebs_block_device.value, "no_device", null)
      snapshot_id           = lookup(ebs_block_device.value, "snapshot_id", null)
      volume_size           = lookup(ebs_block_device.value, "volume_size", null)
      volume_type           = lookup(ebs_block_device.value, "volume_type", null)
    }
  }

  dynamic "root_block_device" {
    for_each = var.root_block_device
    content {
      delete_on_termination = lookup(root_block_device.value, "delete_on_termination", null)
      iops                  = lookup(root_block_device.value, "iops", null)
      volume_size           = lookup(root_block_device.value, "volume_size", null)
      volume_type           = lookup(root_block_device.value, "volume_type", null)
      encrypted             = lookup(root_block_device.value, "encrypted", null)
    }
  }

  depends_on = [
    aws_security_group.efs_sec_group,
    aws_security_group.ecs_sec_group
  ]

  lifecycle {
    create_before_destroy = true
  }
}

####################
# Autoscaling group
####################

resource "aws_autoscaling_group" "this" {
  count = var.create_asg && length(data.aws_subnet_ids.private.ids) > 0 ? length(data.aws_subnet_ids.private.ids) : 0

  name                 = var.asg_name
  launch_configuration = var.create_lc ? element(concat(aws_launch_configuration.this.*.name, [""]), 0) : var.launch_configuration
  max_size             = var.max_size
  min_size             = var.min_size
  desired_capacity     = var.desired_capacity
  vpc_zone_identifier       = [data.aws_subnet.selected[count.index].id]
  load_balancers            = var.load_balancers
  health_check_grace_period = var.health_check_grace_period
  health_check_type         = var.health_check_type

  min_elb_capacity          = var.min_elb_capacity
  wait_for_elb_capacity     = var.wait_for_elb_capacity
  target_group_arns         = var.target_group_arns
  default_cooldown          = var.default_cooldown
  force_delete              = var.force_delete
  termination_policies      = var.termination_policies
  suspended_processes       = var.suspended_processes
  placement_group           = var.placement_group
  wait_for_capacity_timeout = var.wait_for_capacity_timeout
  protect_from_scale_in     = var.protect_from_scale_in
  service_linked_role_arn   = var.service_linked_role_arn
  max_instance_lifetime     = var.max_instance_lifetime


  lifecycle {
    create_before_destroy = true
  }
}

#CloudWatch
############

resource "aws_cloudwatch_metric_alarm" "alarm_mem" {
  count = var.cloudwatch_alarm_cpu_enable ? 1 : 0

  alarm_name        = "MemoryUtilizationAlarmHighEC2"
  alarm_description = "MemoryUtilization > 80% for 5 minutes"
  alarm_actions     = [aws_autoscaling_policy.ecsservermemscaleuppolicy.arn]

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "5"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "80"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}

resource "aws_cloudwatch_metric_alarm" "alarm_cpu" {
  count = var.cloudwatch_alarm_cpu_enable ? 1 : 0

  alarm_name        = "CPUUtilizationAlarmHighEC2"
  alarm_description = "CPUUtilization > 80% for 3 minutes"
  alarm_actions     = [aws_autoscaling_policy.ecsservercpuscaleuppolicy.arn]

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "5"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}

resource "aws_cloudwatch_metric_alarm" "alarm_cpu_low" {
  count = var.cloudwatch_alarm_cpu_enable ? 1 : 0

  alarm_name        = "MemoryUtilizationLowEC2"
  alarm_description = "MemoryUtilization < 30% for 5 minutes"
  alarm_actions     = [aws_autoscaling_policy.ecsservermemscaledownpolicy.arn]

  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "5"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/EC2"
  period              = "30"
  statistic           = "Average"
  threshold           = "30"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}

resource "aws_cloudwatch_metric_alarm" "alarm_mem_low" {
  count = var.cloudwatch_alarm_cpu_enable ? 1 : 0

  alarm_name        = "${local.cloudwatch_alarm_name}-mem"
  alarm_description = "Monitors ECS CPU Utilization"
  alarm_actions     = [aws_autoscaling_policy.ecsservercpuscaledownpolicy.arn]

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "5"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "30"

  dimensions = {
     AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}

resource "aws_autoscaling_policy" "ecsservermemscaleuppolicy" {
  name                   = "ECSServerMemScaleUpPolicy"
  scaling_adjustment     = 1 
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 120
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_autoscaling_policy" "ecsservercpuscaleuppolicy" {
  name                   = "ECSServerCPUScaleUpPolicy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 120
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_autoscaling_policy" "ecsservermemscaledownpolicy" {
  name                   = "ECSServerMemScaleDownPolicy"
  scaling_adjustment     = "-1"
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 120
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_autoscaling_policy" "ecsservercpuscaledownpolicy" {
  name                   = "ECSServerCPUScaleDownPolicy"
  scaling_adjustment     = "-1"
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 120
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

