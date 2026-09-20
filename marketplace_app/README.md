# Sharetribe Flutter marketplace

A small Flutter app that signs in to Sharetribe and displays published listings.
The UI includes loading, empty, error, retry and pull-to-refresh states.

## Requirements

- Flutter with Dart `>=3.11.4 <4.0.0`, as required by `pubspec.yaml`. The local SDK at documentation time is Flutter 3.41.6 / Dart 3.11.4.
- A configured device or emulator and its Flutter platform toolchain (`flutter doctor`).
- A Sharetribe development/test environment, a Marketplace API application's public client ID, an existing marketplace user and a published listing.

Prepare these resources using the [Sharetribe setup](../sharetribe/README.md#setup).
Sign in with marketplace user credentials, rather than Console administrator credentials.

## Setup and run

From the repository root:

```sh
cd marketplace_app
```

Create `.env` in this directory:

```dotenv
SHARETRIBE_CLIENT_ID=your-client-id
```

Copy the public client ID from **Build > Advanced > Applications** in Sharetribe
Console, selecting the same environment as your user and listings. Use a
Marketplace API application. See Sharetribe's [application credential guidance](https://www.sharetribe.com/developer-blog/sharetribe-postman-collection/).

The `.env` file is a declared Flutter asset and must exist before running or
building. It is ignored by Git. Only the public client ID belongs here; do not
bundle client secrets, admin API keys, passwords or user tokens.

```sh
flutter pub get
flutter devices
flutter run -d YOUR_DEVICE_ID
```

Replace `YOUR_DEVICE_ID` with an ID from `flutter devices`. This starts a debug build.
Sign in with the marketplace user's email and password.

## Code structure

```text
lib/
  main.dart                 # Initialization and dependency injection
  core/
    api/                    # Dio client, bearer token and session refresh
    config/                 # API URL and public client ID
    storage/                # Secure token persistence
  features/
    auth/
      data/                 # Token model, service and repository
      bloc/                 # Authentication events and states
      presentation/         # Login page and authentication gate
    listings/
      data/                 # Listing model, service and repository
      bloc/                 # Listing events and states
      presentation/         # Listings screen
test/                       # API client, BLoC and widget tests
```

Widgets dispatch BLoC events; BLoCs call repositories; services make HTTP requests.
Constructor injection lets tests substitute mocks without changing production code.

Login uses `POST /v1/auth/token`. Tokens are stored with `flutter_secure_storage`.
The API client attaches the access token and attempts refresh on a 401 response.
Logout clears local tokens. Listings come from `GET /v1/api/listings/query` and
are displayed using their title and description.

## Validation

Run from `marketplace_app/` after creating `.env` and installing dependencies:

```sh
flutter analyze
flutter test
```

Tests cover selected authentication, listing, startup, session-expiry and refresh
behavior using mocks. They do not verify a live marketplace or every platform target.

Manual checks against your environment:

1. Sign in and confirm a published listing's title/description appears.
2. Pull to refresh and confirm the indicator finishes after the request.
3. Log out, try an incorrect password and confirm an error appears on login.
4. Sign in again and restart the app to check saved-session behavior.

## Scope and troubleshooting

- Only the first page of listings is fetched; pagination and listing details are outside this demo.
- Accounts and listings must already exist; registration and listing creation are not implemented.
- Transaction operations are demonstrated separately in the [Sharetribe README](../sharetribe/README.md).
- The run instructions target a debug demo. Release builds and all platform targets require separate validation.

If startup fails, check that `.env` exists. If login fails, confirm the client ID
and user belong to the same environment. If the list is empty, confirm there is a
published listing visible to the signed-in user in that environment.
