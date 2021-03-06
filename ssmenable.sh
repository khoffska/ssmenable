#!/bin/bash

read -p "Enter Company name:" companyname
s3bucket=$(echo $companyname"-patchinstaller")
snsnamePRD=$(echo $companyname"-PRD-Instances")
snsnameDEV=$(echo $companyname"-PRD-Instances")
maintrole=$(echo $companyname"-MaintenanceRole")
snspubrole=$(echo $companyname"-SNSPublishPermissions")
snsnotrole=$(echo $companyname"-SNSNotifications")
snsinstancerole=$(echo $companyname"-SNSNotificationsinstancerole")


#createsnstopic
aws sns create-topic --name  PRD-Instances
snstopic=$(aws sns list-topics --output text --query Topics | grep PRD)
aws sns subscribe --topic-arn "$snstopic" --protocol email --notification-endpoint khoffstad@cloudnexa.com
aws sns create-topic --name  DEV-Instances
snstopic=$(aws sns list-topics --output text --query Topics | grep DEV-Instances)
aws sns subscribe --topic-arn "$snstopic" --protocol email --notification-endpoint khoffstad@cloudnexa.com


#SNSNotificationsrole
aws iam create-policy --policy-name $snspubrole --policy-document file://snspublish.json
aws iam create-role --role-name $snsnotrole --assume-role-policy-document file://trust.json
publishrole=$(aws iam list-policies --query 'Policies[?PolicyName==`SNSPublishPermissions`].Arn' --output text)
aws iam attach-role-policy --policy-arn "$publishrole" --role-name $snsnotrole
aws iam create-instance-profile --instance-profile-name $snsinstancerole
aws iam add-role-to-instance-profile --role-name $snsnotrole --instance-profile-name $snsinstancerole

#maintenencewindowrole
aws iam create-role --role-name $maintrole --assume-role-policy-document file://trust.json
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/service-role/AmazonSSMMaintenanceWindowRole --role-name $maintrole
snsrole=$(aws iam list-roles --query 'Roles[?RoleName==`SNSNotifications`].Arn' --output text)
sed -i "s@replaceme@$snsrole@g" IAMpassrolesns.json
aws iam put-role-policy --role-name $maintrole --policy-name IAMpassrolesns --policy-document file://IAMpassrolesns.json

#creates3buckets companynameinstaller companynameinstaller/prd/aza 12 months companyname-12months
aws s3 mb s3://${s3bucket}
touch file
aws s3 cp file s3://${s3bucket}/prd/aza
aws s3api put-bucket-lifecycle --bucket ${s3bucket} --lifecycle-configuration file://lifecycle.json

maintrole=$(aws iam list-roles --query 'Roles[?RoleName==`MaintenanceWindowRole`].Arn' --output text)


echo "IAM service role is $maintrole"
echo "Bucket name is $s3bucket"
echo "IAM role for SNS is $snsrole"
