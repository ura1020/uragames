#!/bin/bash

# "awscli" run outside container.

aws s3api create-bucket \
  --bucket uragames \
  --region ap-northeast-1 \
  --create-bucket-configuration LocationConstraint=ap-northeast-1

aws s3 website s3://uragames/ \
  --index-document index.html \
  --error-document index.html

aws s3api put-bucket-policy \
  --bucket uragames \
  --policy file://policy.json

aws s3 cp dist s3://uragames/ \
  --recursive
