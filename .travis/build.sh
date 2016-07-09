#!/bin/bash
set -ex

docker build -t "$IMAGE" .

if [ $TRAVIS_PULL_REQUEST == "false" ] && [ $TRAVIS_BRANCH == "master" ]; then
  docker tag "$IMAGE" "${REPO}:${REVISION}-${JDK}"
  if [ -n "$TAG" ]; then docker tag "$IMAGE" "${REPO}:${TAG}"; fi
  docker login -e="$DOCKER_EMAIL" -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD"
  docker push $REPO
else
  echo "skipping docker push"
fi
