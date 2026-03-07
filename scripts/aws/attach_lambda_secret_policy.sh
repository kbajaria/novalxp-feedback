#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  attach_lambda_secret_policy.sh --profile PROFILE --role-name ROLE --secret-arn ARN
EOF
}

PROFILE=""
ROLE_NAME=""
SECRET_ARN=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) PROFILE="$2"; shift 2 ;;
    --role-name) ROLE_NAME="$2"; shift 2 ;;
    --secret-arn) SECRET_ARN="$2"; shift 2 ;;
    *) usage; exit 1 ;;
  esac
done

[[ -n "$PROFILE" && -n "$ROLE_NAME" && -n "$SECRET_ARN" ]] || { usage; exit 1; }

POLICY_FILE="$(mktemp)"
cat > "$POLICY_FILE" <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["secretsmanager:GetSecretValue"],
      "Resource": "$SECRET_ARN"
    }
  ]
}
EOF

AWS_PROFILE="$PROFILE" aws iam put-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-name NovaLXPFeedbackReadSecret \
  --policy-document "file://$POLICY_FILE" >/dev/null

rm -f "$POLICY_FILE"
echo "Attached secret-read policy for $SECRET_ARN to $ROLE_NAME"
