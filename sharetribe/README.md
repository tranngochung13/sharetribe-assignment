# Sharetribe Transaction Process

## Overview

The default inquiry process allows a customer to send an inquiry to a provider, but the transaction remains in the `free-inquiry` state without an explicit outcome.

To make the inquiry flow clearer, I extended the process so the provider can either **accept** or **decline** the inquiry.

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

This keeps the original inquiry behavior simple while adding a clear outcome for the provider's decision.

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

I tested the flow by:

1. Creating an inquiry as a customer using `custom-inquiry/release-1`.
2. Confirming the transaction moved to `free-inquiry`.
3. Executing `accept-inquiry` as the listing provider.
4. Confirming the transition completed successfully and the transaction moved to `accepted`.

The decline transition provides the alternative path from `free-inquiry` to `declined`.

## Security

API keys, access tokens, passwords, and other credentials are not included in the repository.