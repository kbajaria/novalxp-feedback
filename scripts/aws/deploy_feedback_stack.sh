#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  deploy_feedback_stack.sh \
    --profile PROFILE \
    --region REGION \
    --env ENV \
    --lambda-role-arn ARN \
    --moodle-role-name ROLE \
    --trello-key KEY \
    --trello-token TOKEN \
    --trello-list-id ID
EOF
}

PROFILE=""
REGION=""
ENV_NAME=""
LAMBDA_ROLE_ARN=""
MOODLE_ROLE_NAME=""
TRELLO_KEY=""
TRELLO_TOKEN=""
TRELLO_LIST_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) PROFILE="$2"; shift 2 ;;
    --region) REGION="$2"; shift 2 ;;
    --env) ENV_NAME="$2"; shift 2 ;;
    --lambda-role-arn) LAMBDA_ROLE_ARN="$2"; shift 2 ;;
    --moodle-role-name) MOODLE_ROLE_NAME="$2"; shift 2 ;;
    --trello-key) TRELLO_KEY="$2"; shift 2 ;;
    --trello-token) TRELLO_TOKEN="$2"; shift 2 ;;
    --trello-list-id) TRELLO_LIST_ID="$2"; shift 2 ;;
    *) usage; exit 1 ;;
  esac
done

[[ -n "$PROFILE" && -n "$REGION" && -n "$ENV_NAME" && -n "$LAMBDA_ROLE_ARN" && -n "$MOODLE_ROLE_NAME" && -n "$TRELLO_KEY" && -n "$TRELLO_TOKEN" && -n "$TRELLO_LIST_ID" ]] || { usage; exit 1; }

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FUNCTION_NAME="novalxp-feedback-$ENV_NAME"
SECRET_NAME="novalxp/feedback/$ENV_NAME/trello"

SECRET_ARN="$($ROOT_DIR/scripts/aws/upsert_trello_secret.sh \
  --profile "$PROFILE" \
  --region "$REGION" \
  --secret-name "$SECRET_NAME" \
  --trello-key "$TRELLO_KEY" \
  --trello-token "$TRELLO_TOKEN" \
  --trello-list-id "$TRELLO_LIST_ID")"

$ROOT_DIR/scripts/aws/attach_lambda_secret_policy.sh \
  --profile "$PROFILE" \
  --role-name "${LAMBDA_ROLE_ARN##*/}" \
  --secret-arn "$SECRET_ARN"

$ROOT_DIR/scripts/aws/deploy_lambda.sh \
  --profile "$PROFILE" \
  --region "$REGION" \
  --function-name "$FUNCTION_NAME" \
  --role-arn "$LAMBDA_ROLE_ARN" \
  --secret-arn "$SECRET_ARN"

$ROOT_DIR/scripts/aws/attach_moodle_invoke_policy.sh \
  --profile "$PROFILE" \
  --role-name "$MOODLE_ROLE_NAME" \
  --region "$REGION" \
  --function-name "$FUNCTION_NAME"

echo "Feedback stack deployed for environment: $ENV_NAME"
echo "Lambda function: $FUNCTION_NAME"
echo "Secret ARN: $SECRET_ARN"
