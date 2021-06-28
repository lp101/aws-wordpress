#!/usr/bin/env bash

env='prod'
tmp_dir='/tmp'
wordpress_zip_file_name="wordpress-$(date +%Y%m%d%H%M).zip"

path_wordpress_source=$1
[ -d "$path_wordpress_source" ] || { echo "You must provide a directory with the wordpress source code with .ebextension configured for AWS."; exit 1;} 
[ -e "$path_wordpress_source/wp-config.php" ] || { echo "Cannot found $path_wordpress_source/wp-config.php into wordpress directory"; exit 1;}
while IFS='' read -r row || [[ -n "$row" ]]; do
    row=$(echo -e "${row}" | tr -d '[:space:]')
    eval $row
done < <(terraform output)

echo "VPC Id:             $vpc_id"
echo "EFS Subnet Zone a:  $subnet_efs_a_id"
echo "EFS Subnet Zone b:  $subnet_efs_b_id"
echo "EFS Subnet Zone c:  $subnet_efs_c_id"
echo "S3 Bucket:          $s3_bucket"
echo "Beanstalk Env Name: $beanstalk_env_name"
echo "Beanstalk App Name: $beanstalk_app_name"
echo "AWS Profile:        $aws_profile"
echo "Zip file to deploy: $wordpress_zip_file_name"
echo "Wordpress source:   $path_wordpress_source"

# Update EFS VPC Id and subnets in the conf file, and create the zip file of wordpress
cd $path_wordpress_source
efs_conf='.ebextensions/efs-create.config'
conf_vpcid=$(cat .ebextensions/efs-create.config | grep 'VPCId: "vpc-')
sed -i "s/$conf_vpcid/    VPCId: \"$vpc_id\"/" $efs_conf
conf_subneta=$(cat .ebextensions/efs-create.config | grep 'SubnetA: "subnet-')
sed -i "s/$conf_subneta/    SubnetA: \"$subnet_efs_a_id\"/" $efs_conf
conf_subnetb=$(cat .ebextensions/efs-create.config | grep 'SubnetB: "subnet-')
sed -i "s/$conf_subnetb/    SubnetB: \"$subnet_efs_b_id\"/" $efs_conf
conf_subnetc=$(cat .ebextensions/efs-create.config | grep 'SubnetC: "subnet-')
sed -i "s/$conf_subnetc/    SubnetC: \"$subnet_efs_c_id\"/" $efs_conf

# Create ZIP file 
zip $tmp_dir/$wordpress_zip_file_name -r * .[^.]* -x '*.git*'

# Upload it to S3 bucket
echo "Copy $tmp_dir/$wordpress_zip_file_name to s3://$s3_bucket/$env/"
aws s3 --profile $aws_profile cp $tmp_dir/$wordpress_zip_file_name "s3://$s3_bucket/$env/"

# Create application version and update the environment
echo "Deploy $wordpress_zip_file_name to Beanstalk env $beanstalk_env_name app $beanstalk_app_name"
aws elasticbeanstalk create-application-version --profile $aws_profile --application-name $beanstalk_app_name --version-label $wordpress_zip_file_name --source-bundle S3Bucket=$s3_bucket,S3Key=$env/$wordpress_zip_file_name
[ $? -ne 0 ] && { echo "Failed to create Beanstalk application version for $wordpress_zip_file_name application $beanstalk_app_name."; exit 1;}
aws elasticbeanstalk update-environment --profile $aws_profile --environment-name $beanstalk_env_name --version-label $wordpress_zip_file_name
[ $? -ne 0 ] && { echo "Failed to update Beanstalk env for $wordpress_zip_file_name environment $beanstalk_env_name."; exit 1;}
# Wait for completition
echo "[$(date +%Y%m%d_%H%M%S)] Waiting for completition..."
#aws elasticbeanstalk wait environment-updated --profile $aws_profile --environment-name $beanstalk_env_name --version-label $wordpress_zip_file_name --output text
# Timeout after 30 minutes
sleep_seconds=30
max_num_checks=120
count=0
for i in $(seq 1 $max_num_checks); do
    sleep $sleep_seconds
    status=$(aws elasticbeanstalk describe-environment-health --environment-name $beanstalk_env_name --attribute-names "Status" --query 'Status' --output text)
    if [ "$status" != "Updating" ]; then
        if [ $count -gt 3 ]; then
            if [ "$status" == "Ready" ]; then
                # Get current deployed version
                version=$(aws elasticbeanstalk describe-environments --environment-names $beanstalk_env_name --query 'Environments[0].VersionLabel' --output text)
                if [ "$version" == "$wordpress_zip_file_name" ]; then
                    echo "[OK] AWS Beanstalk environment updated successfully with new version $wordpress_zip_file_name."
                else
                    echo "[ERROR] Failed to update AWS Beanstalk environment with new version $wordpress_zip_file_name."
                    echo "[ERROR] Current version: $version."

                fi
            else
                echo "[ERROR] Failed to update AWS Beanstalk environment with new version $wordpress_zip_file_name."
            fi
            echo "Beanstalk status: $status"
            break
        fi
        count=$((count+1))
    fi
done
date
exit 0