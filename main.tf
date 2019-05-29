provider "aws" {
  region = "us-east-1"
  variable = "AWS_ACCESSKEY"
  variable = "AWS_SECRETCODE"
}


locals {
  app_name = "rbd-metadata-ingest"
  env_name = "staging"

  #reuse existing sg + vpc
  eb_subnet = "subnet-a7950aef" #UMG_DDS_STG_Private1
  eb_security_group = "sg-7b4e5105" #aws27-useast-stage-system_access
  loadbal_subnet = "subnet-fa9a05b2" #UMG_DDS_STG_Semi-Private1
  target_vpc = "vpc-27af745e" #UMG_DDS_STG_VPC

  certificate_name = "2017_umusic_net_chain"
  role = "rbd_metadata_ingest_role"

  eb_instance_type = "t3.medium"
  eb_root_volume_type = "gp2"
  eb_root_volume_size = "50"
  autoscaling-min-size = "1"
  autoscaling-max-size = "1"
  autoscaling-lower-threshold = "40"
  autoscaling-upper-threshold = "70"

  jvm_xmx = "3072m"
  jvm_xms = "1024m"
  jvm_maxpermsize = "64m"
  jvm_options = "-XX:NewSize=128m -Xss4m"

  common_tags = {
    Environment = "Staging"
    Application-Role = "AWSL/App"
    Cost-Center = "US1C0228"
    Project-ID = "754000"
    Application-Code = "APP01187"
    Application-Name = "UWS"
  }
}


###################################################################################################################
#
# Resource Section
#
###################################################################################################################
resource "aws_elastic_beanstalk_application" "staging-rbd-metadata-ingest" {
  name        = "${local.app_name}"
  description = "RBD Metadata Ingest"
}


resource "aws_elastic_beanstalk_environment" "staging-rbd-metadata-ingest" {
  name = "${local.env_name}-${local.app_name}"
  application = "${aws_elastic_beanstalk_application.staging-rbd-metadata-ingest.name}"
  tier = "WebServer"
  solution_stack_name = "64bit Amazon Linux 2018.03 v3.0.5 running Tomcat 8.5 Java 8"

  # see https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/command-options-general.html#command-options-general-autoscalinglaunchconfiguration for all options
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "EC2KeyName"
    value = "UMUSIC_KEY_1"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "IamInstanceProfile"
    value = "${local.role}"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "SecurityGroups"
    value = "${local.eb_security_group}"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "SSHSourceRestriction"
    value = "tcp, 22, 22, ${local.eb_security_group}"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "InstanceType"
    value = "${local.eb_instance_type}"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "RootVolumeType"
    value = "${local.eb_root_volume_type}"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "RootVolumeSize"
    value = "${local.eb_root_volume_size}"
  }

  # --- Auto-scaling settings
  setting {
    namespace = "aws:autoscaling:asg"
    name = "MinSize"
    value = "${local.autoscaling-min-size}"
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name = "MaxSize"
    value = "${local.autoscaling-max-size}"
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name = "Cooldown"
    value = "360"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name = "Statistic"
    value = "Average"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name = "MeasureName"
    value = "CPUUtilization"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name = "Unit"
    value = "Percent"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name = "Statistic"
    value = "Average"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name = "LowerThreshold"
    value = "${local.autoscaling-lower-threshold}"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name = "UpperThreshold"
    value = "${local.autoscaling-upper-threshold}"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name = "Period"
    value = "5"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name = "UpperBreachScaleIncrement"
    value = "1"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name = "BreachDuration"
    value = "5"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name = "EvaluationPeriods"
    value = "2"
  }
  # ---

  setting {
    namespace = "aws:ec2:vpc"
    name = "VPCId"
    value = "${local.target_vpc}"
  }
  setting {
    namespace = "aws:ec2:vpc"
    name = "Subnets"
    value = "${local.eb_subnet}"
  }
  setting {
    namespace = "aws:ec2:vpc"
    name = "ELBSubnets"
    value = "${local.loadbal_subnet}"
  }
  setting {
    namespace = "aws:ec2:vpc"
    name = "ELBScheme"
    value = "internal"
  }
  setting {
    namespace = "aws:ec2:vpc"
    name = "AssociatePublicIpAddress"
    value = "false"
  }


  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "spring.profiles.active"
    value = "${local.env_name}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "CREATE_TAGS"
    value = "${local.env_name}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "LOGSTASH_ENV_FOLDER"
    value = "${local.env_name}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "NESSUS_ENV"
    value = "${local.env_name}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "com.sun.management.jmxremote.authenticate"
    value = "false"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "com.sun.management.jmxremote.port"
    value = "8099"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "com.sun.management.jmxremote.rmi.port"
    value = "8099"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "com.sun.management.jmxremote.ssl"
    value = "false"
  }


  setting {
    namespace = "aws:elasticbeanstalk:command"
    name = "DeploymentPolicy"
    value = "Rolling"
  }
  setting {
    namespace = "aws:elasticbeanstalk:command"
    name = "BatchSizeType"
    value = "Percentage"
  }
  setting {
    namespace = "aws:elasticbeanstalk:command"
    name = "BatchSize"
    value = "30"
  }


  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name = "ServiceRole"
    value = "aws-elasticbeanstalk-service-role"
  }


  setting {
    namespace = "aws:elb:healthcheck"
    name = "Timeout"
    value = "5"
  }
  setting {
    namespace = "aws:elb:healthcheck"
    name = "Interval"
    value = "10"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application"
    name = "Application Healthcheck URL"
    value = "/actuator/health"
  }

  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name = "AWSEBHealthdGroupId"
    value = "${local.env_name}-${local.app_name}-healthreporting"
  }

  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name = "SystemType"
    value = "enhanced"
  }

  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name = "HealthCheckSuccessThreshold"
    value = "Ok"
  }

  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name = "ConfigDocument"
    value = "{\"Rules\": {\"Environment\": {\"Application\": {\"ApplicationRequests4xx\": {\"Enabled\": false}}}},  \"Version\": 1}"
  }


  setting {
    namespace = "aws:elasticbeanstalk:hostmanager"
    name = "LogPublicationControl"
    value = "true"
  }


  setting {
    namespace = "aws:elb:loadbalancer"
    name = "LoadBalancerHTTPSPort"
    value = "443"
  }
  setting {
    namespace = "aws:elb:loadbalancer"
    name = "CrossZone"
    value = "true"
  }
  setting {
    namespace = "aws:elb:loadbalancer"
    name = "LoadBalancerHTTPPort"
    value = "OFF"
  }
  setting {
    namespace = "aws:elb:loadbalancer"
    name = "SSLCertificateId"
    value = "arn:aws:iam::379237304985:server-certificate/${local.certificate_name}"
  }


  setting {
    namespace = "aws:elb:listener:443"
    name = "InstancePort"
    value = "80"
  }
  setting {
    namespace = "aws:elb:listener:443"
    name = "ListenerProtocol"
    value = "HTTPS"
  }
  setting {
    namespace = "aws:elb:listener:443"
    name = "SSLCertificateId"
    value = "arn:aws:iam::379237304985:server-certificate/${local.certificate_name}"
  }
  setting {
    namespace = "aws:elb:listener:443"
    name = "ListenerEnabled"
    value = "true"
  }


  setting {
    namespace = "aws:elb:policies"
    name = "ConnectionDrainingEnabled"
    value = "true"
  }


  setting {
    namespace = "aws:elasticbeanstalk:container:tomcat:jvmoptions"
    name = "Xmx"
    value = "${local.jvm_xmx}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:container:tomcat:jvmoptions"
    name = "XX:MaxPermSize"
    value = "${local.jvm_maxpermsize}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:container:tomcat:jvmoptions"
    name = "Xms"
    value = "${local.jvm_xms}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:container:tomcat:jvmoptions"
    name = "JVM Options"
    value = "${local.jvm_options}"
  }

  tags = "${local.common_tags}"

}
