#!/bin/bash

# Creates Docker image and registers it in ECR.

user=ec2-user

dockerfile=$1
docker_tag=$(echo ${dockerfile} | sed -e 's|.*Dockerfile.||')

aws_account_id=$(aws sts get-caller-identity --output text --query Account)
authorization_token=$(aws ecr get-authorization-token --output text --query authorizationData[].authorizationToken)

docker build -f ${dockerfile} --tag ${docker_tag} . &&
    docker tag ${docker_tag} ${aws_account_id}.dkr.ecr.us-east-1.amazonaws.com/packager &&
    (echo ${authorization_token} | docker login --password-stdin --no-include-email --region us-east-1) &&
    docker push ${aws_account_id}.dkr.ecr.us-east-1.amazonaws.com/packager

