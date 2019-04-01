#!/bin/bash -evx

for docker_tag in packager{,.node}
do
  $(dirname $0)/register-docker-image.sh Dockerfile.${docker_tag}
done

