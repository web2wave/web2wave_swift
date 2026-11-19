## Unreleased

- `updateUserProperty` (and the `set*ProfileID` helpers) now return the server's `error_msg` (or `message`) as the error description on non-2xx responses, e.g. a 403 when the API key lacks a scope, instead of "Unexpected status code"; the error's `code` is still the HTTP status, and `userInfo["required_scope"]` is set when the server names one
- `updateUserProperty` also accepts a numeric `result: 1`; a 200 response without a successful result now carries the server's `error_msg` when present
- `fetchUserProperties` returns `nil` on error responses (403/422 etc.) instead of an empty dictionary, so a missing scope or unknown user is no longer indistinguishable from "no properties"
- `identify()` and `fetchSubscriptionStatus` log the server's `error_msg` on error responses

## 1.2.0

- Add `setApphudProfileID` and `setSuperwallProfileID` (sync web subscriptions to Apphud / Superwall)

## 1.1.0

- Send `device_model` header for identify fingerprinting (utsname machine id, e.g. "iPhone15,2")

## 1.0.1

- Fingerprint headers and `identify()` deferred deeplink support
