#!/bin/bash
#companyname="testcompany"
#basearn=$(aws sts get-caller-identity --query Arn | sed 's/[",]//g')
#sed -i "s/externalid/$externalid/" trust.json

#createsnstopic
aws sns create-topic --name  PRD-Instances
snstopic=$(aws sns list-topics --output text --query Topics | grep PRD)
aws sns subscribe --topic-arn "$snstopic" --protocol email --notification-endpoint khoffstad@cloudnexa.com
aws sns create-topic --name  DEV-Instances
snstopic=$(aws sns list-topics --output text --query Topics | grep DEV-Instances)
aws sns subscribe --topic-arn "$snstopic" --protocol email --notification-endpoint khoffstad@cloudnexa.com


#SNSNotificationsrole
aws iam create-policy --policy-name SNSPublishPermissions --policy-document file://snspublish.json
aws iam create-role --role-name SNSNotifications --assume-role-policy-document file://trust.json
publishrole=$(aws iam list-policies --query 'Policies[?PolicyName==`SNSPublishPermissions`].Arn' --output text)
aws iam attach-role-policy --policy-arn "$publishrole" --role-name SNSNotifications
aws iam create-instance-profile --instance-profile-name SNSNotificationsinstancerole
aws iam add-role-to-instance-profile --role-name SNSNotifications --instance-profile-name SNSNotificationsinstancerole



#maintenencewindowrole
aws iam create-role --role-name MaintenanceWindowRole --assume-role-policy-document file://trust.json
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/service-role/AmazonSSMMaintenanceWindowRole --role-name MaintenanceWindowRole
cat IAMpassrolesns.json | sed 's/replaceme/SNSNotifications/g' | tee IAMpassrolesns.json
aws iam create-policy --policy-name IAMpassrolesns --policy-document file://IAMpassrolesns.json --output text
snsrole=$(aws iam list-roles --query 'Roles[?RoleName==`SNSNotifications`].Arn' --output text)
sed -i "s@replaceme@$snsrole@g" IAMpassrolesns.json
aws iam attach-role-policy --policy-arn "$snsrole" --role-name MaintenanceWindowRole





#creates3buckets companynameinstaller companynameinstaller/prd/aza 12 months companyname-12months
aws s3 mb s3://patchinstaller123412345
touch file
aws s3 cp file s3://patchinstaller123412345/prd/aza
aws s3api put-bucket-lifecycle --bucket patchinstaller123412345 --lifecycle-configuration file://lifecycle.json



echo "Sns topic is $snstopic"
echo "RoleARN is $rolearn "


#RENOVA-MaintenanceWindowRole - AmazonSSMMaintenanceWindowRole - RENOVA-IAMPassRoleSNS (InlinePolicy)
#RENOVASNSNotifications - RENOVA-SNSPublishPermissions
