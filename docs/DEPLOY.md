# Deployment Guide

This repository contains enough to deploy the NovaLXP feedback feature to new environments, provided you also apply the Edutor theme patch and have access to the target AWS account and Moodle hosts.

## What gets deployed

- Moodle plugin: `local/novalxpfeedback`
- Lambda function: `aws/lambda`
- Trello secret in Secrets Manager
- IAM permission from the Moodle instance role to the Lambda function
- Edutor patch: `patches/edutor-featured-feedback.patch`

## Prerequisites

- AWS CLI configured for the target account
- Access to the Moodle codebase and target EC2 host
- AWS CLI installed on the Moodle host
- The Moodle host role must be known
- Node/npm available on the machine used to package the Lambda

## AWS deployment

1. Create or update the Trello secret.
2. Create or update the Lambda execution role.
3. Deploy the Lambda package.
4. Grant the Moodle instance role permission to invoke the Lambda.

Use the scripts in `scripts/aws`.

### One-command path

```bash
scripts/aws/deploy_feedback_stack.sh \
  --profile finova-sso \
  --region eu-west-2 \
  --env test \
  --lambda-role-arn arn:aws:iam::ACCOUNT_ID:role/novalxp-feedback-test-lambda-role \
  --moodle-role-name YOUR_MOODLE_INSTANCE_ROLE \
  --trello-key "$TRELLO_KEY" \
  --trello-token "$TRELLO_TOKEN" \
  --trello-list-id "$TRELLO_LIST_ID"
```

### Example for test

```bash
scripts/aws/upsert_trello_secret.sh \
  --profile finova-sso \
  --region eu-west-2 \
  --secret-name novalxp/feedback/test/trello \
  --trello-key "$TRELLO_KEY" \
  --trello-token "$TRELLO_TOKEN" \
  --trello-list-id "$TRELLO_LIST_ID"

scripts/aws/deploy_lambda.sh \
  --profile finova-sso \
  --region eu-west-2 \
  --function-name novalxp-feedback-test \
  --role-arn arn:aws:iam::ACCOUNT_ID:role/novalxp-feedback-test-lambda-role \
  --secret-arn arn:aws:secretsmanager:eu-west-2:ACCOUNT_ID:secret:novalxp/feedback/test/trello-XXXX

scripts/aws/attach_moodle_invoke_policy.sh \
  --profile finova-sso \
  --role-name YOUR_MOODLE_INSTANCE_ROLE \
  --region eu-west-2 \
  --function-name novalxp-feedback-test
```

### Scripts included

- `scripts/aws/upsert_trello_secret.sh`
- `scripts/aws/attach_lambda_secret_policy.sh`
- `scripts/aws/deploy_lambda.sh`
- `scripts/aws/attach_moodle_invoke_policy.sh`
- `scripts/aws/deploy_feedback_stack.sh`

## Moodle plugin deployment

1. Copy `local/novalxpfeedback` into the target Moodle codebase under `local/`.
2. Run Moodle upgrade.
3. Configure plugin settings:
   - `lambdafunctionname`
   - `lambdaregion`
4. Purge caches.

## Edutor patch deployment

Apply `patches/edutor-featured-feedback.patch` to the target codebase containing the Edutor theme.

Example:

```bash
cd /path/to/moodle/public
patch -p1 < /path/to/novalxp-feedback/patches/edutor-featured-feedback.patch
```

If the patch does not apply cleanly, reproduce the changes manually in:
- `theme/edutor/classes/output/core_renderer.php`
- `theme/edutor/templates/fp_featured.mustache`

## Verification

- Load the front page and open the second featured pane.
- Confirm the multiline textarea is visible and centered.
- Submit a test message.
- Confirm a Trello card appears in the target list.
