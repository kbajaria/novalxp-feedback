#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  deploy_lambda.sh --profile PROFILE --region REGION --function-name NAME --role-arn ARN --secret-arn ARN [--endpoint-token TOKEN]
EOF
}

PROFILE=""
REGION=""
FUNCTION_NAME=""
ROLE_ARN=""
SECRET_ARN=""
ENDPOINT_TOKEN="dev-function-url-token"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) PROFILE="$2"; shift 2 ;;
    --region) REGION="$2"; shift 2 ;;
    --function-name) FUNCTION_NAME="$2"; shift 2 ;;
    --role-arn) ROLE_ARN="$2"; shift 2 ;;
    --secret-arn) SECRET_ARN="$2"; shift 2 ;;
    --endpoint-token) ENDPOINT_TOKEN="$2"; shift 2 ;;
    *) usage; exit 1 ;;
  esac
done

[[ -n "$PROFILE" && -n "$REGION" && -n "$FUNCTION_NAME" && -n "$ROLE_ARN" && -n "$SECRET_ARN" ]] || { usage; exit 1; }

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LAMBDA_DIR="$ROOT_DIR/aws/lambda"
BUILD_DIR="$LAMBDA_DIR/.build"
ZIP_FILE="$BUILD_DIR/function.zip"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cp "$LAMBDA_DIR/index.mjs" "$LAMBDA_DIR/package.json" "$BUILD_DIR/"
pushd "$BUILD_DIR" >/dev/null
npm install --omit=dev >/dev/null
zip -qr "$ZIP_FILE" .
popd >/dev/null

if AWS_PROFILE="$PROFILE" aws lambda get-function --region "$REGION" --function-name "$FUNCTION_NAME" >/dev/null 2>&1; then
  AWS_PROFILE="$PROFILE" aws lambda update-function-code \
    --region "$REGION" \
    --function-name "$FUNCTION_NAME" \
    --zip-file "fileb://$ZIP_FILE" >/dev/null
else
  AWS_PROFILE="$PROFILE" aws lambda create-function \
    --region "$REGION" \
    --function-name "$FUNCTION_NAME" \
    --runtime nodejs22.x \
    --handler index.handler \
    --role "$ROLE_ARN" \
    --zip-file "fileb://$ZIP_FILE" \
    --timeout 30 \
    --memory-size 256 >/dev/null
fi

AWS_PROFILE="$PROFILE" aws lambda update-function-configuration \
  --region "$REGION" \
  --function-name "$FUNCTION_NAME" \
  --environment "Variables={TRELLO_SECRET_ARN=$SECRET_ARN,ENDPOINT_TOKEN=$ENDPOINT_TOKEN}" >/dev/null

echo "Deployed $FUNCTION_NAME in $REGION"
