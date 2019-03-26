#!/bin/bash

[[ "$AWS_ACCESS_KEY_ID" ]] || { echo "Aws access key id doesn't exist in env variable. Please set it"; exit; }
[[ "$AWS_SECRET_ACCESS_KEY" ]] || { echo "Aws secret key id doesn't exist in env variable. Please set it"; exit; }
[[ "$AWS_DEFAULT_REGION" ]] || { echo "Aws default region doesn't exist in env variable. Please set it"; exit; }


export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
ECR_REPO_NAME=bgdemo
COMMIT_TAG=${CI_COMMIT_SHA:0:8}
ECR_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com"
ECR_PATH="$ECR_URL/$ECR_REPO_NAME"
STATE_FILE=bluegreendemo/terraform.state
BUCKET=tf-state-${AWS_ACCOUNT_ID}-${AWS_DEFAULT_REGION}

#Creates bucket for terraform state file if not exists
bucket_check=$(aws s3api head-bucket --bucket $bucket 2>&1)
if [[ -z $bucket_check ]]; then
  echo "S3 Bucket ${BUCKET} exists"
elif [[ $AWS_DEFAULT_REGION == "us-east-1" ]]; then
  echo "Creating s3 Bucket ${BUCKET}"
  aws s3api create-bucket --bucket ${BUCKET} --region ${AWS_DEFAULT_REGION}
else
  echo "Creating s3 Bucket ${BUCKET}"
  aws s3api create-bucket --bucket ${BUCKET} --region ${AWS_DEFAULT_REGION} --create-bucket-configuration LocationConstraint=${AWS_DEFAULT_REGION}
fi

# Create ecr repo if not exists
aws ecr describe-repositories --repository-names $ECR_REPO_NAME 2>&1 > /dev/null
status=$?
if [[ ! "${status}" -eq 0 ]]; then
    aws ecr create-repository --repository-name $ECR_REPO_NAME
fi


if [ "$1" == "dockerize" ];then
    find build/libs/ -type f \( -name "*.jar" -not -name "*sources.jar" \) -exec cp {} deploy/app.jar \;

    login=`aws ecr get-login --no-include-email --region ${AWS_DEFAULT_REGION}`
    eval $login

    cd deploy
    echo "Docker will build your image: ${ECR_REPO_NAME}:${COMMIT_TAG}\n"
    docker build -t ${ECR_REPO_NAME}:${COMMIT_TAG} .
    docker tag ${ECR_REPO_NAME}:${COMMIT_TAG} ${ECR_PATH}:${COMMIT_TAG}
    docker push ${ECR_PATH}:${COMMIT_TAG}
fi

if [ "$1" == "deploy" ]; then
    cd deploy/terraform
    terraform init --backend-config "bucket=$BUCKET" --backend-config "key=${STATE_FILE}" --backend-config "region=${AWS_DEFAULT_REGION}"
    terraform plan -var "image_url=$ECR_URL/$ECR_REPO_NAME:$COMMIT_TAG" -var "domain_name=$DOMAIN_NAME"
    terraform apply -auto-approve -var "image_url=$ECR_URL/$ECR_REPO_NAME:$COMMIT_TAG" -var "domain_name=$DOMAIN_NAME"
fi


if [ "$1" == "destroy" ]; then
    cd deploy/terraform
    terraform init --backend-config "bucket=$BUCKET" --backend-config "key=${STATE_FILE}" --backend-config "region=${AWS_DEFAULT_REGION}"
    terraform destroy -var "image_url=$ECR_URL/$ECR_REPO_NAME:$COMMIT_TAG" -var "domain_name=$DOMAIN_NAME" --force

    # If you want to destroy ECR repo, please uncomment below lines..
#    aws ecr describe-repositories --repository-names $ECR_REPO_NAME 2>&1 > /dev/null
#    status=$?
#    if [[ ! "${status}" -eq 1 ]]; then
#        aws ecr delete-repository --repository-name $ECR_REPO_NAME
#    fi
fi
