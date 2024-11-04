# Web2Wave

Web2Wave is a lightweight Swift package that provides a simple interface for managing user subscriptions and properties through a REST API.

## Features

- Fetch subscription status for users
- Check for active subscriptions
- Manage user properties
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
Web2Wave.shared.baseURL = URL(string: "[whatever].web2wave.com/quiz/[without api etc.]")
Web2Wave.shared.apiKey = "your-api-key"
```

## Usage

### Checking Subscription Status

```swift
// Fetch detailed subscription status
let status = await Web2Wave.shared.fetchSubscriptionStatus(userID: "user123")

// Check if user has an active subscription
let isActive = await Web2Wave.shared.hasActiveSubscription(userID: "user123")
```

### Managing User Properties

```swift
// Fetch user properties
if let properties = await Web2Wave.shared.fetchUserProperties(userID: "user123") {
    print("User properties: \(properties)")
}

// Update a user property
let result = await Web2Wave.shared.updateUserProperty(
    userID: "user123",
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

## API Reference

### `Web2Wave.shared`

The singleton instance of the Web2Wave client.

### Methods

#### `fetchSubscriptionStatus(userID: String) async -> [String: Any]?`
Fetches the subscription status for a given user ID.

#### `hasActiveSubscription(userID: String) async -> Bool`
Checks if the user has an active subscription (including trial status).

#### `fetchUserProperties(userID: String) async -> [String: String]?`
Retrieves all properties associated with a user.

#### `updateUserProperty(userID: String, property: String, value: String) async -> Result<Void, Error>`
Updates a specific property for a user.

## Requirements

- iOS 13.0+ / macOS 10.15+
- Swift 5.5+
- Xcode 13.0+

## License

MIT

## Author

Igor Kamenev
