# Web2Wave

Web2Wave is a lightweight Swift package that provides a simple interface for managing user subscriptions and properties through a REST API.

## Features

- Fetch subscription status for users
- Check for active subscriptions
- Manage user properties
- web2wave deferred deeplinks via `identify()`
- Set third-parties profiles
- Thread-safe singleton design
- Async/await API support
- Built-in error handling

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/web2wave/web2wave_swift.git", from: "1.0.0")
]
```

## Setup

Before using Web2Wave, you need to configure the base URL and API key:

```swift
Web2Wave.shared.apiKey = "your-api-key"
```

## Usage

### Checking Subscription Status

```swift
// Fetch subscriptions
let status = await Web2Wave.shared.fetchSubscriptions(web2waveUserId: "user123")

// Check if user has an active subscription
let isActive = await Web2Wave.shared.hasActiveSubscription(web2waveUserId: "user123")
```

### Managing User Properties

```swift
// Fetch user properties
if let properties = await Web2Wave.shared.fetchUserProperties(web2waveUserId: "user123") {
    print("User properties: \(properties)")
}

// Update a user property
let result = await Web2Wave.shared.updateUserProperty(
    web2waveUserId: "user123",
    property: "preferredTheme",
    value: "dark"
)

switch result {
case .success:
    print("Property updated successfully")
case .failure(let error):
    print("Failed to update property: \(error)")
}
```

### web2wave deferred deeplinks

The `identify()` method resolves a web2wave user via **deferred deeplinks** and returns identification metadata including the `user_id`. Use it as an **alternative to MMP attribution** (AppsFlyer, Adjust, Branch, etc.) when you do not run those tools — call it on first app launch instead of reading an install deeplink.

```swift
if let identificationData = await Web2Wave.shared.identify(),
   let success = identificationData["success"] as? Int, success == 1,
   let userId = identificationData["user_id"] as? String {
    print("Identified user: \(userId)")

    let _ = await Web2Wave.shared.setAdaptyProfileID(
        web2waveUserId: userId,
        adaptyProfileID: "{adaptyProfileID}"
    )
} else {
    print("Failed to identify user")
}
```

**Response format:**

```json
{
  "success": 1,
  "user_id": "identified_user_guid",
  "match_method": "match_method_used",
  "platform": "iOS"
}
```

### Managing third-party profiles
```swift

// Save Adapty profileID
let result = await Web2Wave.shared.setAdaptyProfileID(
    web2waveUserId: "user123", 
    adaptyProfileID: "{adaptyProfileID}"
)

switch result {
case .success:
    print("ProfileID saved")
case .failure(let error):
    print("Failed to save profileID: \(error)")
}


// Save Revenue Cat profileID
let _ = await Web2Wave.shared.setRevenuecatProfileID(
    web2waveUserId: "user123",
    revenueCatProfileID: "{revenueCatProfileID}"
)

// Save Qonversion profileID
let _ = await Web2Wave.shared.setQonversionProfileID(
    web2waveUserId: "user123",
    qonversionProfileID: "{qonversionProfileID}"
)

```

### Working with quiz or landing web page
```swift

//Extend Web2WaveWebListener class to receive events
extension ViewController: Web2WaveWebListener {
    func onEvent(event: String, data: [String : Any]?) {
        print("Event received: \(event), data: \(data ?? [:])")
    }
    
    func onClose(data: [String : Any]?) {
        print("WebView closed with data: \(data ?? [:])")
        Web2Wave.shared.closeWebView(currentVC: self)
    }
    
    func onQuizFinished(data: [String : Any]?) {
        print("Quiz finished! Result: \(data ?? [:])")
        Web2Wave.shared.closeWebView(currentVC: self)
    }
}

//Open web page with your url
Web2Wave.shared.showWebView(
    currentVC: self,
    urlString: url,
    topOffset: topOffset,
    bottomOffset: bottomOffset,
    delegate: self,
    backgroundColor: backgroundColor
)

//Close web page
Web2Wave.shared.closeWebView(currentVC: self)
```
The backgroundColor parameter in showWebView function is optional. If not provided, the default background color will be white.

## API Reference

### `Web2Wave.shared`

The singleton instance of the Web2Wave client.

### Methods

#### `fetchSubscriptionStatus(web2waveUserId: String) async -> [String: Any]?`
Fetches the subscription status for a given user ID.

#### `hasActiveSubscription(web2waveUserId: String) async -> Bool`
Checks if the user has an active subscription (including trial status).

#### `fetchUserProperties(web2waveUserId: String) async -> [String: String]?`
Retrieves all properties associated with a user.

#### `updateUserProperty(web2waveUserId: String, property: String, value: String) async -> Result<Void, Error>`
Updates a specific property for a user.

#### `setRevenuecatProfileID(web2waveUserId: String, revenueCatProfileID: String) -> Void`
Set Revenuecat profileID

#### `setAdaptyProfileID(web2waveUserId: String, adaptyProfileID: String) -> Void`
Set Adapty profileID

#### `setQonversionProfileID(web2waveUserId: String, qonversionProfileID: String) -> Void`
Set Qonversion ProfileID

#### `identify() async -> [String: Any]?`
Resolves a user via web2wave deferred deeplinks. Alternative to MMP-based deeplink attribution.

## Requirements

- iOS 13.0+ / macOS 10.15+
- Swift 5.5+
- Xcode 13.0+

## License

MIT

## Author

Igor Kamenev

