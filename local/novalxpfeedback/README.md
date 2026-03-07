# NovaLXP front-page feedback for AWS Lambda

This plugin adds an inline feedback widget to the Moodle front page and invokes an AWS Lambda function to process learner feedback.

## What it does

- Accepts free-text learner feedback from the Moodle front page.
- Invokes an AWS Lambda function from the Moodle app server.
- Keeps Trello credentials out of Moodle.
- Supports an AWS Lambda integration that creates a Trello card on board `NovaLXP Roadmap` in list `Feedback`.

## Moodle plugin install

1. Copy `local/novalxpfeedback` into your Moodle codebase under `local/novalxpfeedback`.
2. Visit `Site administration -> Notifications` to complete installation.
3. Go to `Site administration -> Plugins -> Local plugins -> NovaLXP feedback`.
4. Set `Lambda function name` to your feedback Lambda function.
5. Set `Lambda region` to the function region, for example `eu-west-2`.
6. Purge caches.

## Edutor integration

The widget is rendered in the second featured panel by the Edutor theme patch already applied on the dev instance. If you need to reproduce that manually, render this template from the relevant theme PHP:

```php
$widget = new \local_novalxpfeedback\output\widget();
echo $OUTPUT->render_from_template('local_novalxpfeedback/widget', $widget->export_for_template($OUTPUT));
```

## Lambda payload contract

Moodle invokes Lambda with:

```json
{
  "feedback": "text",
  "userid": 123,
  "fullname": "Learner Name",
  "email": "user@example.com",
  "username": "username",
  "siteurl": "https://dev.novalxp.co.uk",
  "submittedat": "2026-03-07T15:00:00Z"
}
```

Moodle expects a JSON response like:

```json
{
  "status": true,
  "message": "Thanks. Your feedback has been sent."
}
```

## AWS Lambda deployment

Lambda source is in `aws/lambda`.

### Required environment variables

- `TRELLO_KEY`: Trello API key
- `TRELLO_TOKEN`: Trello API token
- `TRELLO_LIST_ID`: Trello list ID for `Feedback`
- `ENDPOINT_TOKEN`: optional bearer token used only if you also expose the Lambda through a Function URL or HTTP entrypoint

### Example zip and deploy

```bash
cd aws/lambda
zip -r function.zip index.mjs package.json
aws lambda update-function-code \
  --function-name novalxp-feedback-dev \
  --zip-file fileb://function.zip
```

### Example environment update

```bash
aws lambda update-function-configuration \
  --function-name novalxp-feedback-dev \
  --environment "Variables={TRELLO_KEY=replace-me,TRELLO_TOKEN=replace-me,TRELLO_LIST_ID=69186475ee521327994deb91,ENDPOINT_TOKEN=replace-me-if-needed}"
```

### Moodle server permissions

The Moodle EC2 instance role needs permission to invoke the Lambda function:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "lambda:InvokeFunction",
      "Resource": "arn:aws:lambda:eu-west-2:ACCOUNT_ID:function:novalxp-feedback-dev"
    }
  ]
}
```

The plugin currently invokes Lambda through the AWS CLI using the instance role on the Moodle host. That avoids the blocked public egress path to Trello and Lambda Function URLs.

## Recommended security

- Store `TRELLO_KEY` and `TRELLO_TOKEN` in AWS Secrets Manager or SSM Parameter Store and inject them into Lambda.
- Remove old Trello credentials from Moodle after switching to Lambda.
