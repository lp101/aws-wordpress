# EC2 Security Group for beanstalk
resource "aws_security_group" "beanstalk-wordpress-sg" {
  name   = "beanstalk-wordpress-sg"
  vpc_id = module.vpc.vpc_id
  description = "Beanstalk Security Group for wordpress"
  # ingress {
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   #cidr_blocks = [aws_subnet.lb-subnet-a.cidr_block,aws_subnet.lb-subnet-b.cidr_block,aws_subnet.lb-subnet-c.cidr_block]
  #   cidr_blocks = ["0.0.0.0/0"]
  #   description = "Inbound rule from ALB subnets."
  # }
  tags = {
    Name = "beanstalk-wordpress-sg"
  }
}
# Define application
resource "aws_elastic_beanstalk_application" "wordpressapp" {
  name        = "wordpress-test"
  description = "AWS Elastic Beanstalk Application."
}
# Define environment
resource "aws_elastic_beanstalk_environment" "wordpressenv" {
  name                = "wordpress-test"
  application         = aws_elastic_beanstalk_application.wordpressapp.name
  solution_stack_name = "64bit Amazon Linux 2 v3.3.1 running PHP 8.0"

  # Networking
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = module.vpc.vpc_id
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", [aws_subnet.ec2-subnet-a.id,aws_subnet.ec2-subnet-b.id,aws_subnet.ec2-subnet-c.id])
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = join(",", [aws_subnet.lb-subnet-a.id,aws_subnet.lb-subnet-b.id,aws_subnet.lb-subnet-c.id])
  }

  # Load balancer
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }
  setting {
    namespace = "aws:elb:loadbalancer"
    name      = "CrossZone"
    value     = "true"
  }
  setting {
    namespace = "aws:elb:policies"
    name      = "ConnectionDrainingEnabled"
    value     = "true"
  }
  # EC2
  setting {
    namespace = "aws:ec2:instances"
    name      = "InstanceTypes"
    value     = "c5.large,c4.large,t3.medium"
  }
  setting {
    namespace = "aws:ec2:instances"
    name      = "EnableSpot"
    value     = true
  }
  setting {
    namespace = "aws:ec2:instances"
    name      = "SpotFleetOnDemandBase"
    value     = 2
  }
  # Lauch Configuration
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "aws-elasticbeanstalk-ec2-role"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "EC2KeyName"
    value     = "adagio-usa-eu.pem"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.beanstalk-wordpress-sg.id
  }
  # Autoscaling settings
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = 2
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = 20
  }
  setting { # Default values - ScaleIn: -1, ScaleOut: 1, BreachDuration: 5
    namespace = "aws:autoscaling:trigger"
    name      = "MeasureName"
    value     = "CPUUtilization"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "LowerThreshold"
    value     = "20"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "UpperThreshold"
    value     = "60"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Unit"
    value     = "Percent"
  }
  # Health check
  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
  }
  # setting {
  #   namespace = "aws:elasticbeanstalk:application"
  #   name      = "Application Healthcheck URL"
  #   value     = ""
  # }

  # Deployments
  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "RollingUpdateEnabled"
    value     = true
  }
  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "RollingUpdateType"
    value     = "Health"
  }
  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "DeploymentPolicy"
    value     = "RollingWithAdditionalBatch"
  }
  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "BatchSizeType"
    value     = "Fixed"
  }
  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "BatchSize"
    value     = "1"
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "MatcherHTTPCode"
    value     = "200,302"
  }

  # Env vars
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_DB_NAME"
    value     = module.db.rds_cluster_database_name
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_HOSTNAME"
    value     = module.db.rds_cluster_endpoint
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_PORT"
    value     = module.db.rds_cluster_port
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_USERNAME"
    value     = "${var.rds_username}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_PASSWORD"
    value     = "${module.db.rds_cluster_master_password}"
  }
}
