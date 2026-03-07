# NovaLXP Feedback

This repository contains the NovaLXP learner feedback feature built for Moodle 5.1.3 with the Edutor theme.

## Architecture

The production path is:

`Moodle front page widget -> Moodle AJAX external function -> AWS Lambda invoke -> Trello card creation`

This design avoids direct outbound calls from the Moodle app server to Trello, which are blocked by the corporate firewall on the dev environment.

## Repository layout

- `local/novalxpfeedback`: Moodle local plugin providing the front-page widget and AJAX submission handler
- `aws/lambda`: Lambda function that receives feedback payloads and creates Trello cards

## Moodle plugin behavior

- Renders an inline, multiline feedback widget in the second featured pane on the front page
- Submits learner feedback through Moodle AJAX
- Invokes an AWS Lambda function using the AWS CLI and the EC2 instance role
- Returns a user-facing success/error message to the widget

## AWS Lambda behavior

- Accepts payloads from Moodle invoke requests and optionally HTTP events
- Builds a Trello card title and description from learner feedback and metadata
- Creates the card in the configured Trello list

## Important deployment notes

- The Moodle host must have AWS CLI available
- The Moodle host instance role must be allowed to invoke the Lambda function
- Trello credentials should live in Lambda configuration or a secret source, not in Moodle
- The Edutor theme requires a small renderer/template patch to place the widget in pane 2

## Dev status

The feature has been validated on the dev NovaLXP environment with successful end-to-end card creation in Trello.

See [local/novalxpfeedback/README.md](local/novalxpfeedback/README.md) for plugin and Lambda deployment details.
