# NovaLXP Feedback

This repository contains the NovaLXP learner feedback feature built for Moodle 5.1.3 with the Edutor theme.

## Architecture

The production path is:

`Moodle front page widget -> Moodle AJAX external function -> AWS Lambda invoke -> Trello card creation`

This design avoids direct outbound calls from the Moodle app server to Trello, which are blocked by the corporate firewall on the dev environment.

## Repository layout

- `local/novalxpfeedback`: Moodle local plugin providing the front-page widget and AJAX submission handler
- `aws/lambda`: Lambda function that receives feedback payloads and creates Trello cards
- `patches/edutor-featured-feedback.patch`: Edutor patch for the second featured pane
- `scripts/aws`: deployment scripts for Secrets Manager, Lambda, and IAM wiring
- `docs/DEPLOY.md`: end-to-end deployment guide for dev, test, and prod

## Moodle plugin behavior

- Renders an inline, multiline feedback widget in the second featured pane on the front page
- Submits learner feedback through Moodle AJAX
- Invokes an AWS Lambda function using the AWS CLI and the EC2 instance role
- Returns a user-facing success/error message to the widget

## AWS Lambda behavior

- Accepts payloads from Moodle invoke requests and optionally HTTP events
- Builds a Trello card title and description from learner feedback and metadata
- Creates the card in the configured Trello list

## Deployment completeness

This repo now contains the pieces required to deploy the feature to additional environments:

- Moodle plugin source
- Lambda source
- AWS deployment scripts
- Edutor patch artifact
- deployment documentation

What still happens against the target environment at deploy time:

- copy the plugin into the target Moodle codebase
- apply the Edutor patch in the target theme codebase
- run the AWS deployment scripts with the correct environment values

## Dev status

The feature has now been validated in all target environments with successful end-to-end card creation in Trello:

- `dev` at `https://dev.novalxp.co.uk`
- `test` at `https://test.novalxp.co.uk`
- `prod` at `https://learn.novalxp.co.uk`

Deployed Lambda functions:

- `novalxp-feedback-dev`
- `novalxp-feedback-test`
- `novalxp-feedback-prod`

Deployed Secrets Manager secrets:

- `novalxp/feedback/dev/trello`
- `novalxp/feedback/test/trello`
- `novalxp/feedback/prod/trello`

Shared Moodle invoke policy choice:

- The Moodle instance role `MoodleCombinedSSMAndBedrockRole` is intentionally shared across environments.
- It is configured to invoke all three feedback Lambda functions.

Primary references:

- [docs/DEPLOY.md](docs/DEPLOY.md)
- [local/novalxpfeedback/README.md](local/novalxpfeedback/README.md)
