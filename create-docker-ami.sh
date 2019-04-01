#!/bin/bash -evx

# Creates AMI with Docker.

umask 0022

ami_name=docker

image_id=$(aws ec2 describe-images --output text --query 'Images[].ImageId' --filter Name=tag:app,Values=node)
security_group_ids=sg-0252c5c7a1eeec1b3

instance_ids=$(aws ec2 run-instances --image-id "${image_id}" --tag-specifications "ResourceType=instance,Tags=[{Key=app,Value=${ami_name} AMI template}]" --count 1 --instance-type t2.micro --security-group-ids "${security_group_ids}" --output text --query 'Instances[].InstanceId')
echo "instance_ids = [${instance_ids}]"

if [ -z "${instance_ids}" ]
then
  echo Error
  exit 1
fi

timeout=60
while [[ -z "${public_ip_address}" && ${timeout} -ne 0 ]]
do
  sleep 1
  ((--timeout))

  public_ip_address=$(aws ec2 describe-instances --instance-ids ${instance_ids} --output text --query 'Reservations[].Instances[].PublicIpAddress')
done

key=~/.ssh/aws.pem
user=ec2-user

timeout=60
while ! ssh -o 'StrictHostKeyChecking no' -i ${key} ${user}@${public_ip_address} "sudo yum update -y && sudo amazon-linux-extras install docker -y && sudo usermod -a -G docker ec2-user && sudo systemctl enable docker" && ${timeout} -ne 0
do
  sleep 1
  ((--timeout))
done

aws ec2 stop-instances --instance-ids ${instance_ids}

timeout=60
while [ "${public_ip_address}" != 'null' -a ${timeout} -ne 0 ]
do
  sleep 1
  ((--timeout))

  public_ip_address=$(aws ec2 describe-instances --instance-ids ${instance_ids} --output text --query 'Reservations[].Instances[].PublicIpAddress')
done

image_id=$(aws ec2 create-image --instance-id ${instance_ids} --name "${ami_name}" --output text --query 'ImageId')

aws terminate-instances --instance-ids ${instance_ids}

echo "image_id = [${image_id}]"

