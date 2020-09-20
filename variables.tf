variable "Environment" {
  type        = string
  description = "Choose the environment configuration. Choose from sandbox, dev, mgmt, test, or prod"
}

variable "DesiredCapacity" {
  type        = number
  description = "Number of instances to launch in your ECS cluster."
}

variable "MaxSize" {
  type        = number
  description = "Maximum number of instances that can be launched in your ECS cluster."
}

variable "CreatedBy" {
  type = string
}

variable "APMID" {
  type        = string
  description = "APM ID."
}

variable "FMC" {
  type        = string
  description = "FMC(GL-TagFMC-BU-Client)."
}

variable "BusinessSegment" {
  type = string
}

variable "AppRole" {
  type = string
}

variable "BillingApprover" {
  type = string
}

variable "BusinessTower" {
  type = string
}

variable "Service" {
  type = string
}

variable "SupportGroup" {
  type = string
}

variable "EBSSize" {
  type    = list(map(string))
  default = []
}

variable "EFSMountPoint" {
  type = string
}

variable "RegionToEFSSubnetIP" {
  type = any
}

#variable "RegionToEFSSubnetIP-us-east-2" {
#  type = list(map(string))
#}

variable "ECSStackName" {
  type = string
}

variable "EFSStackName" {
  type = string
}

variable "stackname" {
  type = string
}

#Security Group
#################

variable "vpc_id" {
  type = string
}

variable "ports_cidr" {
  type = list
}

#Launch Configuration
#####################
variable "region" {
  type = string
}

variable "create_lc" {
  description = "Whether to create launch configuration"
  type        = bool
  default     = true
}

variable "create_asg" {
  description = "Whether to create autoscaling group"
  type        = bool
  default     = true
}

variable "cluster_name" {
  type = string
}

variable "lc_name" {
  description = "Creates a unique name for launch configuration beginning with the specified prefix"
  type        = string
}

variable "image_id" {
  description = "The EC2 image ID to launch"
  type        = map(string)
}

variable "instance_type" {
  description = "The size of instance to launch"
  type        = string
}

variable "key_name" {
  description = ""
  type        = string
}

variable "iam_instance_profile" {
  description = "The IAM instance profile to associate with launched instances"
  type        = string
}

variable "security_groups" {
  description = "A list of security group IDs to assign to the launch configuration"
  type        = list(string)
  default     = ["myagsec"]
}

variable "associate_public_ip_address" {
  description = "Associate a public ip address with an instance in a VPC"
  type        = bool
  default     = false
}

variable "user_data" {
  description = "The user data to provide when launching the instance. Do not pass gzip-compressed data via this argument; see user_data_base64 instead."
  type        = string
  default     = null
}

variable "ecs_config" {
  default     = "echo '' > /etc/ecs/ecs.config"
  description = "Specify ecs configuration or get it from S3. Example: aws s3 cp s3://some-bucket/ecs.config /etc/ecs/ecs.config"
}

variable "custom_userdata" {
  default     = ""
  description = "Inject extra command in the instance template to be run on boot"
}

variable "ecs_logging" {
  default     = "[\"json-file\",\"awslogs\"]"
  description = "Adding logging option to ECS that the Docker containers can use. It is possible to add fluentd as well"
}

variable "user_data_base64" {
  description = "Can be used instead of user_data to pass base64-encoded binary data directly. Use this instead of user_data whenever the value is not a valid UTF-8 string. For example, gzip-encoded user data must be base64-encoded and passed via this argument to avoid corruption."
  type        = string
  default     = null
}

variable "enable_monitoring" {
  description = "Enables/disables detailed monitoring. This is enabled by default."
  type        = bool
  default     = false
}

variable "ebs_optimized" {
  description = "If true, the launched EC2 instance will be EBS-optimized"
  type        = bool
  default     = false
}

variable "root_block_device" {
  description = "Customize details about the root block device of the instance"
  type        = list(map(string))
  default = [{
  volume_size = 8 }]
}

variable "ebs_block_device" {
  description = "Additional EBS block devices to attach to the instance"
  type        = list(map(string))
}

variable "spot_price" {
  description = "The price to use for reserving spot instances"
  type        = string
  default     = ""
}

variable "efs_mountpoint" {
  default = ""
  type    = string
}

variable "asg_grp" {
  default = ""
  type    = string
}

#CloudWatch
############

variable "cloudwatch_alarm_name" {
  description = "Generic name used for CPU and Memory Cloudwatch Alarms"
  default     = ""
  type        = string
}
