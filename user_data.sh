    echo "ECS_CLUSTER=${cluster_name}" >> /etc/ecs/ecs.config

    cat > /etc/cfn/cfn-hup.conf <<- EOF
    mode: 000400
    owner: root
    group: root
    [main]
    stack={stackid}
    region={region}
    EOF

    cat > /etc/cfn/hooks.d/cfn-auto-reloader.conf <<-EOF
    [cfn-auto-reloader-hook]
    triggers=post.update
    path=Resources.ECSLaunchConfiguration.Metadata.AWS::CloudFormation::Init
    action=/opt/aws/bin/cfn-init -v --region {region} --stack {stackname} --resource {lc_config}
    EOF

    cfn-hup -c /etc/cfn/
  
    exec &> >(tee -a /var/log/user-data.log | logger -t user-data)
    echo BEGIN
    date '+%Y-%m-%d %H:%M:%S'
    yum update -y
    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
    yum install -y https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
    yum install -y aws-cfn-bootstrap hibagent
    yum install -y aws-cfn-bootstrap nfs-utils device-mapper-persistent-data lvm2 unzip
    PATH=$PATH:/usr/local/bin
   
    #################################################################
    # Update ECS Agent.
    #################################################################
    yum update -y ecs-init
    systemctl restart docker

    ######################################
    # Begin Init
    ######################################
    /opt/aws/bin/cfn-init -v --stack {cluster_name} --resource {ecs_config} --region {region} --configsets Install
  
    #################################
    #Subnets
    #################################
    if [ "{region}" = "us-east-1" ] && [ "{environment}" = "prod" ];then
     EFS_SUBNET_AZ_A={subnet_0}
     EFS_SUBNET_AZ_B={subnet_1}
     EFS_SUBNET_AZ_C={subnet_2}
    elif [ "{region}" = "us-east-1" ] && [ "{environment}" = "dev" ];then
     EFS_SUBNET_AZ_A={subnet_3}
     EFS_SUBNET_AZ_B={subnet_4}
     EFS_SUBNET_AZ_C={subnet_5}
    elif [ "{region}" = "us-east-1" ] && [ "{environment}" = "test" ];then
     EFS_SUBNET_AZ_A={subnet_6}
     EFS_SUBNET_AZ_B={subnet_7}
     EFS_SUBNET_AZ_C={subnet_8}
    elif [ "{region}" = "us-west-1" ] && [ "{environment}" = "prod" ] || [ "{environment}" = "test" ] || [ "{environment" = "dev" ];then
     EFS_SUBNET_AZ_A={subnet_9}
     EFS_SUBNET_AZ_B={subnet_10}
     EFS_SUBNET_AZ_C={subnet_11}
    fi

    #################################################################
    # Mount EFS - hack to use ip as using dns name does not work yet
    ##################################################################
    EC2_AVAIL_ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
    echo "AvailabilityZone:$EC2_AVAIL_ZONE"
    #aws efs describe-mount-targets --mount-target-id fsmt-10768658 --region us-east-1 | grep -Po '"IpAddress": *\K"[^"]*"'
    if [ "{EC2_AVAIL_ZONE}" == "us-east-1a" ] || [ "{EC2_AVAIL_ZONE}" == "us-west-2a" ]; then
     EFS_IP={EFS_SUBNET_AZ_A}
    elif [ "{EC2_AVAIL_ZONE}" == "us-east-1b" ] || [ "{EC2_AVAIL_ZONE}" == "us-west-2b" ]; then
     EFS_IP={EFS_SUBNET_AZ_B}
    elif [ "{EC2_AVAIL_ZONE}" == "us-east-1c" ] || [ "{EC2_AVAIL_ZONE}" == "us-west-2c" ]; then
     EFS_IP={EFS_SUBNET_AZ_C}
    fi
    echo "EFS IP:{EFS_IP}"

    #################################################################
    # Update the mounts.
    #################################################################
    cp -p /etc/fstab /etc/fstab.back-$(date +%F)
    mkdir -p ${efs_mountpoint}
    echo $EFS_IP:/ ${efs_mountpoint} nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev 0 0 >> /etc/fstab
    mount -a -t nfs4

    # mount the data volume.
    mkdir /mnt/ebs
    sudo mkfs -t xfs /dev/xvdh
    id=$(sudo blkid | grep "xvdh" | awk '{print $2}')
    echo $id /mnt/ebs xfs defaults 0 0 >> /etc/fstab
    mount -a

    chmod go+rw .

    #######################################################################
    # Install the system monitoring.
    #######################################################################
    sudo yum install -y jq perl-Switch perl-DateTime perl-Sys-Syslog perl-LWP-Protocol-https perl-Digest-SHA.x86_64
    sudo curl https://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.2.zip -O
    unzip CloudWatchMonitoringScripts-1.2.2.zip && \
    rm -f CloudWatchMonitoringScripts-1.2.2.zip && \
    cd aws-scripts-mon
    sudo crontab -l > mycrontab
    sudo echo "*/5 * * * * /aws-scripts-mon/mon-put-instance-data.pl --mem-used-incl-cache-buff --mem-util --disk-space-util --disk-path=/ --from-cron" >> mycrontab
    sudo echo "*/5 * * * * /aws-scripts-mon/mon-put-instance-data.pl --mem-used-incl-cache-buff --mem-util --disk-space-util --disk-path=/var/lib/docker/devicemapper/mnt/ --from-cron" >> mycrontab
    sudo crontab mycrontab

    #######################################################################
    # update the timekeeping.
    #######################################################################
    yum remove -y ntp
    yum install -y chrony
    TagService chronyd start
    chkconfig chronyd on

    #######################################################################
    # echo the state.
    #######################################################################
    touch /home/ec2-user/echo.res
    EC2_REGION={region}
    echo $EC2_REGION >> /home/ec2-user/echo.res
    echo $EC2_AVAIL_ZONE >> /home/ec2-user/echo.res

    #######################################################################
    # send signal of completion.
    #######################################################################
    /opt/aws/bin/cfn-signal -e $? --region {region} --stack {stackname} --resource {asg_group}

    ##################################
    # Update bash profile
    ##################################
    echo 'export PS1="[\u@\h \w]$ "' >> /home/ec2-user/.bash_profile
    echo "alias ls='ls -alrt --color=tty'" >> /home/ec2-user/.bash_profile

    2> /dev/null
    sleep 30
