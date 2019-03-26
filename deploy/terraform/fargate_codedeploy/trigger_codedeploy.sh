#!/bin/bash


function deploy(){
    aws deploy create-deployment --application-name $APPLICATION_NAME \
          --deployment-group-name $DEPLOYMENT_GROUP_NAME \
          --s3-location bucket="tf-state-$AWS_ACCOUNT_ID-$AWS_DEFAULT_REGION",bundleType=JSON,key=appspec.json > deployment_id.out
    aws s3 cp deployment_id.out s3://tf-state-$AWS_ACCOUNT_ID-$AWS_DEFAULT_REGION/deployment_id.out
    echo "Deployment created and deployment id is saved to S3"
}


export APPLICATION_NAME=$1; echo "APPLICATION_NAME= $APPLICATION_NAME"
export DEPLOYMENT_GROUP_NAME=$2; echo "DEPLOYMENT_GROUP_NAME = $DEPLOYMENT_GROUP_NAME"

deployment_file=$(aws s3 cp s3://tf-state-$AWS_ACCOUNT_ID-$AWS_DEFAULT_REGION/deployment_id.out deployment_id.out)
if [[ -e $deployment_file ]]; then
    deployment_id=$(cat deployment_id.out | jq -r '.deploymentId')
    aws deploy get-deployment --deployment-id ${deployment_id} > result.out
    status=$(cat result.out | jq -r '.deploymentInfo.status')

    if [[ $status == "Succeeded" ]] && [[ $status == "Failed" ]] && [[ $status == "Stopped" ]];then
        deploy
    else
        echo "Your deployment with id $deployment_id is already Pending or In Progress"
    fi
else
    deploy
fi

