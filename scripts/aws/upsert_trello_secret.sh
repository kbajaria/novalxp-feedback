#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  upsert_trello_secret.sh --profile PROFILE --region REGION --secret-name NAME --trello-key KEY --trello-token TOKEN --trello-list-id ID
EOF
}

PROFILE=""
REGION=""
SECRET_NAME=""
TRELLO_KEY=""
TRELLO_TOKEN=""
TRELLO_LIST_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) PROFILE="$2"; shift 2 ;;
    --region) REGION="$2"; shift 2 ;;
    --secret-name) SECRET_NAME="$2"; shift 2 ;;
    --trello-key) TRELLO_KEY="$2"; shift 2 ;;
    --trello-token) TRELLO_TOKEN="$2"; shift 2 ;;
    --trello-list-id) TRELLO_LIST_ID="$2"; shift 2 ;;
    *) usage; exit 1 ;;
  esac
done

[[ -n "$PROFILE" && -n "$REGION" && -n "$SECRET_NAME" && -n "$TRELLO_KEY" && -n "$TRELLO_TOKEN" && -n "$TRELLO_LIST_ID" ]] || { usage; exit 1; }

SECRET_FILE="$(mktemp)"
cat > "$SECRET_FILE" <<EOF
{
  "TRELLO_KEY": "$TRELLO_KEY",
  "TRELLO_TOKEN": "$TRELLO_TOKEN",
  "TRELLO_LIST_ID": "$TRELLO_LIST_ID"
}
EOF

if AWS_PROFILE="$PROFILE" aws secretsmanager describe-secret --region "$REGION" --secret-id "$SECRET_NAME" >/dev/null 2>&1; then
  AWS_PROFILE="$PROFILE" aws secretsmanager put-secret-value \
    --region "$REGION" \
    --secret-id "$SECRET_NAME" \
    --secret-string "file://$SECRET_FILE" >/dev/null
else
  AWS_PROFILE="$PROFILE" aws secretsmanager create-secret \
    --region "$REGION" \
    --name "$SECRET_NAME" \
    --secret-string "file://$SECRET_FILE" >/dev/null
fi

AWS_PROFILE="$PROFILE" aws secretsmanager describe-secret --region "$REGION" --secret-id "$SECRET_NAME" --query 'ARN' --output text
rm -f "$SECRET_FILE"
