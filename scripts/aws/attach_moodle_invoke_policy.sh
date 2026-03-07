#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  attach_moodle_invoke_policy.sh --profile PROFILE --role-name ROLE --region REGION --function-name NAME
EOF
}

PROFILE=""
ROLE_NAME=""
REGION=""
FUNCTION_NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) PROFILE="$2"; shift 2 ;;
    --role-name) ROLE_NAME="$2"; shift 2 ;;
    --region) REGION="$2"; shift 2 ;;
    --function-name) FUNCTION_NAME="$2"; shift 2 ;;
    *) usage; exit 1 ;;
  esac
done

[[ -n "$PROFILE" && -n "$ROLE_NAME" && -n "$REGION" && -n "$FUNCTION_NAME" ]] || { usage; exit 1; }

ACCOUNT_ID="$(AWS_PROFILE="$PROFILE" aws sts get-caller-identity --query 'Account' --output text)"
POLICY_FILE="$(mktemp)"
cat > "$POLICY_FILE" <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["lambda:InvokeFunction"],
      "Resource": "arn:aws:lambda:$REGION:$ACCOUNT_ID:function:$FUNCTION_NAME"
    }
  ]
}
EOF

AWS_PROFILE="$PROFILE" aws iam put-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-name NovaLXPFeedbackInvokeLambda \
  --policy-document "file://$POLICY_FILE" >/dev/null

rm -f "$POLICY_FILE"
echo "Attached invoke policy for $FUNCTION_NAME to $ROLE_NAME"
