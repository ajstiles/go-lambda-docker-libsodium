#!/bin/bash

# Name of lambda function. Used to create image, container and binary names.
FUNCTION_NAME=$1
if [[ -z "$1" ]]; then
  echo "usage: ./build_deploy_package.sh function_name"
  exit 1
fi

# Setup some vars to pass docker build
IMAGE_NAME="$FUNCTION_NAME"-image
CONTAINER_NAME="$FUNCTION_NAME"-container
SHARED_BUILD_FOLDER="/build"
BINARY_NAME=$FUNCTION_NAME
PACKAGE_NAME="$BINARY_NAME"_handler.zip

echo "IMAGE_NAME:          $IMAGE_NAME"
echo "CONTAINER_NAME:      $CONTAINER_NAME"
echo "SHARED_BUILD_FOLDER: $SHARED_BUILD_FOLDER"
echo "BINARY_NAME:         $BINARY_NAME"

# Build image, copy deployment package, then remove image.
docker build -t $IMAGE_NAME -f Dockerfile --build-arg SHARED_BUILD_FOLDER=$SHARED_BUILD_FOLDER --build-arg BINARY_NAME=$BINARY_NAME .
docker create --name $CONTAINER_NAME $IMAGE_NAME
docker cp $CONTAINER_NAME:$SHARED_BUILD_FOLDER/$PACKAGE_NAME .
docker rm $CONTAINER_NAME
echo "Deploy package copied to $PACKAGE_NAME"
