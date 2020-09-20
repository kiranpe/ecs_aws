Environment        = "dev"
DesiredCapacity    = 1
MaxSize            = 1
CreatedBy          = "jayant.bamroo@cbre.com"
APMID              = " "
FMC                = " "
BusinessSegment    = " "
AppRole            = "arn:aws:iam::811816443625:role/WSOEC2Role"
BillingApprover    = "jayant.bamroo@cbre.com"
BusinessTower      = " "
Service            = " "
SupportGroup       = " "
EFSMountPoint = " "
stackname     = "ECSCluster"

vpc_id = "vpc-ab1ebfc0"

#Security Group
################

ECSStackName       = "ECSSecurityGroup"
EFSStackName       = "EFSSecurityGroup"
ports_cidr = ["10.0.0.0/8", "10.45.0.0/16", "10.34.0.0/16", "10.70.0.0/16", "172.16.0.0/12"]

#Launch Configuration
#######################

region           = "us-east-1"
cluster_name     = "ecs-cluster"
lc_name          = "ecs_lc_group"
image_id = {
  us-east-1      = "ami-076d6af2f2fec3c54"
  us-west-2      = "ami-0a34f9b326b9bac9b"
  eu-west-1      = "ami-a1491ad2"
  eu-central-1   = "ami-54f5303b"
  ap-northeast-1 = "ami-9cd57ffd"
  ap-southeast-1 = "ami-a900a3ca"
  ap-southeast-2 = "ami-0d591edf536ec9c3a"
}

instance_type    = "t2.micro"
key_name         = "myvpc"
iam_instance_profile = "arn:aws:iam::811816443625:instance-profile/WSOEC2RoleInstanceProfile"
ebs_block_device = [{
  volume_size = 8
  volume_type = "gp2"
  device_name = "/dev/xvdh"
  delete_on_termination = false
}]

RegionToEFSSubnetIP = [{
     devAZ1  = "10.172.200.58"
     devAZ2  = "10.172.201.103"
     devAZ3  = "10.172.202.9"
     testAZ1 = "10.173.200.208"
     testAZ2 = "10.173.201.79"
     testAZ3 = "10.173.202.253"
     prodAZ1 = "10.175.10.88"
     prodAZ2 = "10.175.11.208"
     prodAZ3 = "10.175.12.245"
     drAZ1 = "10.175.200.141"
     drAZ2 = "10.175.201.59"
     drAZ3 = "10.175.202.80"
}]

#CloudWatch
################

