# Sharetribe Transaction Process

## Overview

The default inquiry process allows a customer to send an inquiry to a provider, but the transaction remains in the `free-inquiry` state without an explicit outcome.

To give each inquiry a clear outcome, I extended the process so the provider can either **accept** or **decline** it.

### Before

```text
Customer
   |
   | Send inquiry
   v
free-inquiry
```

### After

```text
Customer
   |
   | Send inquiry
   v
free-inquiry
   |
   +-- Provider accepts --> accepted
   |
   +-- Provider declines --> declined
```

## Approach

I kept the existing customer inquiry flow unchanged and added two provider-controlled transitions:

- `accept-inquiry`: moves the transaction from `free-inquiry` to `accepted`.
- `decline-inquiry`: moves the transaction from `free-inquiry` to `declined`.

This keeps the original inquiry behavior simple while giving the provider a clear way to respond to each inquiry.

The custom process is defined in:

```text
transaction-processes/custom-inquiry/process.edn
```

The relevant transitions are:

```clojure
{:name :transition/accept-inquiry,
 :actor :actor.role/provider,
 :from :state/free-inquiry,
 :to :state/accepted}

{:name :transition/decline-inquiry,
 :actor :actor.role/provider,
 :from :state/free-inquiry,
 :to :state/declined}
```

## Verification

The custom process was deployed as:

```text
Process: custom-inquiry
Version: 2
Alias: custom-inquiry/release-1
```

The flow was verified using the Sharetribe Marketplace API with Postman/cURL.

### 1. Authenticate as customer

```sh
curl --request POST 'https://flex-api.sharetribe.com/v1/auth/token' \
  --header 'Accept: application/json' \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'client_id=YOUR_CLIENT_ID' \
  --data-urlencode 'grant_type=password' \
  --data-urlencode 'scope=user' \
  --data-urlencode 'username=CUSTOMER_EMAIL' \
  --data-urlencode 'password=CUSTOMER_PASSWORD'
```

Save the returned `access_token` as `CUSTOMER_ACCESS_TOKEN`.

### 2. Create an inquiry

Use a published listing owned by the provider:

```sh
curl --request POST \
  'https://flex-api.sharetribe.com/v1/api/transactions/initiate?expand=true' \
  --header 'Accept: application/json' \
  --header 'Content-Type: application/json' \
  --header 'Authorization: bearer CUSTOMER_ACCESS_TOKEN' \
  --data '{
    "processAlias": "custom-inquiry/release-1",
    "transition": "transition/inquire-without-payment",
    "params": {
      "listingId": "PROVIDER_LISTING_UUID"
    }
  }'
```

Save `data.id` from the response as `TRANSACTION_UUID`.

The response should contain:

```text
lastTransition: transition/inquire-without-payment
```

which moves the transaction to `free-inquiry` according to the custom process.

### 3. Authenticate as provider

Sign in with the account that owns the listing:

```sh
curl --request POST 'https://flex-api.sharetribe.com/v1/auth/token' \
  --header 'Accept: application/json' \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'client_id=YOUR_CLIENT_ID' \
  --data-urlencode 'grant_type=password' \
  --data-urlencode 'scope=user' \
  --data-urlencode 'username=PROVIDER_EMAIL' \
  --data-urlencode 'password=PROVIDER_PASSWORD'
```

Save the returned `access_token` as `PROVIDER_ACCESS_TOKEN`.

### 4. Accept the inquiry

Using the provider access token:

```sh
curl --request POST \
  'https://flex-api.sharetribe.com/v1/api/transactions/transition?expand=true' \
  --header 'Accept: application/json' \
  --header 'Content-Type: application/json' \
  --header 'Authorization: bearer PROVIDER_ACCESS_TOKEN' \
  --data '{
    "id": "TRANSACTION_UUID",
    "transition": "transition/accept-inquiry",
    "params": {}
  }'
```

A successful response should contain:

```text
lastTransition: transition/accept-inquiry
```

This verifies the following flow:

```text
Customer inquiry
      |
      v
free-inquiry
      |
      | Provider accepts
      v
accepted
```

### 5. Decline the inquiry

To test the decline path, create a **new inquiry** by repeating step 2, then execute:

```sh
curl --request POST \
  'https://flex-api.sharetribe.com/v1/api/transactions/transition?expand=true' \
  --header 'Accept: application/json' \
  --header 'Content-Type: application/json' \
  --header 'Authorization: bearer PROVIDER_ACCESS_TOKEN' \
  --data '{
    "id": "NEW_TRANSACTION_UUID",
    "transition": "transition/decline-inquiry",
    "params": {}
  }'
```

The expected transition is:

```text
free-inquiry
      |
      | Provider declines
      v
declined
```

A new transaction is required because an already accepted transaction is no longer in the `free-inquiry` state.

## Security

API keys, access tokens, passwords, and other credentials are not included in the repository. Replace all placeholder values locally when verifying the flow.