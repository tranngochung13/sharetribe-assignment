# Sharetribe assignment

A basic Sharetribe integration with a custom inquiry process and a Flutter app
for authentication and browsing listings.

## Source code and setup

| Directory | Contents |
| --- | --- |
| [sharetribe](sharetribe/README.md) | Original/custom processes, email templates, deployment instructions and API walkthrough |
| [marketplace_app](marketplace_app/README.md) | Flutter source, configuration instructions and automated tests |

1. Follow the Sharetribe README to prepare a development/test environment, users, a published listing and a Marketplace API application.
2. Deploy the custom process and exercise it using the API walkthrough.
3. Follow the Flutter README using the public client ID from the same environment.

## Transaction process change

The original inquiry process ends at `free-inquiry`. The custom process adds
provider-only accept and decline transitions, leading to `accepted` or `declined`.
The original inquiry action and provider notification are preserved.

This is an inquiry flow without payments. Transaction operations are demonstrated
through the API. The Flutter app implements login, session handling and listing
display; it does not include a transaction UI.
