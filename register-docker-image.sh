#!/bin/bash

# Creates Docker image and registers it in ECR.

key=~/.ssh/aws.pem
user=ec2-user

dockerfile=$1
docker_tag=$(echo ${dockerfile} | sed -e 's|.*\.|')

aws_account_id=$(aws sts get-caller-identity --output text --query Account)
authorization_token=$(aws ecr get-authorization-token --output text --query authorizationData[].authorizationToken)

docker_ec2_instance=$(aws ec2 describe-instances --filter Name=tag:app,Values=docker --output text --query Reservations[].Instances[].PublicIpAddress)

tmpdir=$(ssh -o 'StrictHostKeyChecking no' -i ${key} "${user}@${docker_ec2_instance}" "mktemp -d")

scp -o 'StrictHostKeyChecking no' -i ${key} ${dockerfile} "${user}@${docker_ec2_instance}:${tmpdir}/$(basename ${dockerfile})"

ssh -o 'StrictHostKeyChecking no' -i ${key} "${user}@${docker_ec2_instance}" "docker build -f ${tmpdir}/$(basename ${dockerfile}) --tag ${docker_tag} . && docker tag ${docker_tag} ${aws_account_id}.dkr.ecr.us-east-1.amazonaws.com/packager && (echo ${authorization_token} | docker login --passwordsstdin --no-include-email --region us-east-1) && docker push ${aws_account_id}.dkr.ecr.us-east-1.amazonaws.com/packager && rm -rf ${tmpdir}"

