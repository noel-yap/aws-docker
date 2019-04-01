#!/bin/bash -evx

# Creates Docker image and registers it in ECR.

aws_account_id=$(aws sts get-caller-identity --output text --query Account)
$(aws ecr get-login --no-include-email --region us-east-1 | sed 's|https://||')

register-docker-image() {
  dockerfile=$1
  docker_tag=$(echo ${dockerfile} | sed -e 's|.*Dockerfile.||')

  docker build -f ${dockerfile} --tag ${docker_tag} . &&
      docker tag ${docker_tag} ${aws_account_id}.dkr.ecr.us-east-1.amazonaws.com/packager
}

for docker_tag in packager{,.node}
do
  register-docker-image $(dirname $0)/Dockerfile.${docker_tag}
done

docker push ${aws_account_id}.dkr.ecr.us-east-1.amazonaws.com/packager
docker logout
