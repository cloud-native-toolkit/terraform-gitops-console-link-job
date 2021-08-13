#!/usr/bin/env bash

GIT_REPO=$(cat git_repo)
GIT_TOKEN=$(cat git_token)

export KUBECONFIG=$(cat .kubeconfig)
NAMESPACE="gitops-console-link-job"
BRANCH="main"
SERVER_NAME="default"
NAME="console-link-job"

mkdir -p .testrepo

git clone https://${GIT_TOKEN}@${GIT_REPO} .testrepo

cd .testrepo || exit 1

find . -name "*"

if [[ ! -f "argocd/2-services/cluster/${SERVER_NAME}/base/${NAMESPACE}-${NAME}.yaml" ]]; then
  echo "ArgoCD config missing - argocd/2-services/cluster/${SERVER_NAME}/base/${NAMESPACE}-${NAME}.yaml"
  exit 1
fi

echo "Printing argocd/2-services/cluster/${SERVER_NAME}/base/${NAMESPACE}-${NAME}.yaml"
cat "argocd/2-services/cluster/${SERVER_NAME}/base/${NAMESPACE}-${NAME}.yaml"

if [[ ! -f "payload/2-services/namespace/${NAMESPACE}/${NAME}/values.yaml" ]]; then
  echo "Application values not found - payload/2-services/namespace/${NAMESPACE}/${NAME}/values.yaml"
  exit 1
fi

echo "Printing payload/2-services/namespace/${NAMESPACE}/${NAME}/values.yaml"
cat "payload/2-services/namespace/${NAMESPACE}/${NAME}/values.yaml"

cd ..
rm -rf .testrepo
