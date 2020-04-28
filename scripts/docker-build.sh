#!/bin/bash -xe

cd "$(dirname $0)"

if ! test -f ../hako/hako.env; then
    echo "hako/hako.env not found"
    exit 1
fi

source ../hako/hako.env

echo "Your GitHub ID: ${github_id}"
github_lower_case=$(echo ${github_id} | tr '[:upper:]' '[:lower:]')

echo "Build and push bff image"

pushd ../bff
revision=$(git rev-parse HEAD)
echo ${revision} > REVISION
docker build -t ${account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${github_lower_case}-bff:latest .
docker tag ${account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${github_lower_case}-bff:latest ${account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${github_lower_case}-bff:${revision}
docker push ${account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${github_lower_case}-bff:latest
docker push ${account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${github_lower_case}-bff:${revision}
popd

echo "Build and push main image"

pushd ../main
revision=$(git rev-parse HEAD)
echo ${revision} > REVISION
docker build -t ${account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${github_lower_case}-main:latest .
docker tag ${account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${github_lower_case}-main:latest ${account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${github_lower_case}-main:${revision}
docker push ${account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${github_lower_case}-main:latest
docker push ${account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${github_lower_case}-main:${revision}
popd

echo "Build and push tsukurepo_backend image"

pushd ../tsukurepo_backend
revision=$(git rev-parse HEAD)
echo ${revision} > REVISION
docker build -t ${account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${github_lower_case}-tsukurepo_backend:latest .
docker tag ${account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${github_lower_case}-tsukurepo_backend:latest ${account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${github_lower_case}-tsukurepo_backend:${revision}
docker push ${account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${github_lower_case}-tsukurepo_backend:latest
docker push ${account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${github_lower_case}-tsukurepo_backend:${revision}
popd
