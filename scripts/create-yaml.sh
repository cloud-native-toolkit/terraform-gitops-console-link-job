#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)
CHART_DIR=$(cd "${SCRIPT_DIR}/../chart/console-link-job"; pwd -P)

OUTPUT_PATH="$1"
SERVICE_ACCOUNT_NAME="$2"

mkdir -p "${OUTPUT_PATH}"

cp -R "${CHART_DIR}"/* "${OUTPUT_PATH}"
cat "${CHART_DIR}/values.yaml" | sed "s/SERVICE_ACCOUNT_NAME/${SERVICE_ACCOUNT_NAME}/g" > "${OUTPUT_PATH}/values.yaml"

echo "Files in output path"
ls -l "${OUTPUT_PATH}"
