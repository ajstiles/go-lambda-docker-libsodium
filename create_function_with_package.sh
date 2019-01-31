#!/bin/bash

# Source our .env file if it exists
if [ -f .env ]; then
  source .env  
fi

# Name of lambda function. Used to create image, container and binary names.
FUNCTION_NAME=$1
if [[ -z "$1" ]]; then
  echo "usage: ./create_function_with_package.sh function_name"
  exit 1
fi

PACKAGE_NAME="$FUNCTION_NAME"_handler.zip

aws lambda create-function \
  --region $REGION \
  --function-name $FUNCTION_NAME \
  --memory 128 \
  --role $ROLE_ARN \
  --runtime go1.x \
  --zip-file fileb://$PACKAGE_NAME \
  --handler $FUNCTION_NAME \
  --profile $PROFILE

# Invoke the new function and show results
RESULTS_FILE=_results.txt
aws lambda invoke --function-name $FUNCTION_NAME \
  --region $REGION \
  --profile $PROFILE \
  $RESULTS_FILE

cat $RESULTS_FILE
echo
rm $RESULTS_FILE
