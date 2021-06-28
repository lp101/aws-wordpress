# aws-wordpress
Wordpress on High-Availability AWS Infrastructure created with Terraform.

## Infrastructure creation and Wordpress deployment
1. Checkout the infrastructure Terraform code and the wordpress code from:
    
    `git clone https://github.com/lp101/aws-wordpress.git`
    
    `git clone https://github.com/lp101/aws-wordpress-code.git`

2. Go inside terraform directory:
    `cd aws-wordpress`

3. Setup your AWSCLI profile and AWS region in **variables.tfvars**

4. Use Terraform commands to deploy/destroy your infrastructure for wordpress.

    `$ terraform init`

    `$ terraform apply`

    `$ terraform destroy`

    The terraform command `terraform init` also prints the DNS beanstalk with which to access to the app.

5. To deploy Wordpress run the deploy script:
    
    `bash deploy_prod.sh /path/to/aws-wordpress-code`
    
    The script deploy to AWS Beanstalk and exits when the application is ready specifying whether the deployment was successful or not.



## Infrastructure description
These terraform configurations create a new VPC and network configurations in which all components will be deployed.
The ec2 instances and the Aurora Mysql database will be deployed in private subnets so as not to be accessible from outside the vpc.

**Infrastructure components:**
- **Custom VPC** with **public subnets** for the Application Load Balancer, Internet Gateway and NAT Gateway.
- The database and ec2 instances have their own **private subnets**, so you can configure communications with routing tables.
- All components are distributed over the **three availability zones** for high availability and fault tolerance.
- **AWS Aurora Mysql** was used with a **read copy** in another AZ; This parameter is configurable in the Terraform **variables.tfvars** file.
- **AWS Beanstalk** was used for deployment, autoscaling and app management, which distributes the instances in the three AZs. The deployment is performed on one ec2 at a time only if the new version passes the Health check. 
Autoscaling ranges from a minimum of 2 instances to a maximum of 20. Two instances are always available on demand, scaling is performed with spot instances to lower costs.
- An **EFS** filesystem is shared between ec2 instances where the application saves local files, making them available to all instances.
