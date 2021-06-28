# aws-wordpress
Wordpress on High-Availability AWS Infrastructure created with Terraform.

### Infrastructure creation
1. Checkout the infrastructure Terraform code:
    `git clone https://github.com/lp101/aws-wordpress.git`
2. Setup your AWSCLI profile and AWS region in **variables.tfvars**
3. Use Terraform to deploy your infrastructure.

    `$ terraform init`

    `$ terraform apply`

    `$ terraform destroy`


### Infrastructure description
The infrastructure is made up of an Aurora Mysql db, a pool of ec2 in autoscaling managed by aws beanstalk, which also creates an application load balancer.
The instances scale from 2 to 20, based on the use of the cpu, distributed among the 3 AZ.

Each ec2 mounts the same EFS in which to store local files.


