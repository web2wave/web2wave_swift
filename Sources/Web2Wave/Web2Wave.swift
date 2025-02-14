//
//  Web2Wave.swift
//  Web2Wave
//
//  Created by Igor Kamenev on 02.11.24.
//

import Foundation

public class Web2Wave: @unchecked Sendable {
    
    public static let shared = Web2Wave()
    
    private let baseURL: URL = URL(string: "https://api.web2wave.com")!
    public var apiKey: String?
            
    public func fetchSubscriptionStatus(userID: String) async -> [String: Any]? {

        assert(nil != apiKey, "You have to initialize apiKey before use")
        
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent("api")
                                                            .appendingPathComponent("user")
                                                            .appendingPathComponent("subscriptions"),
                                          resolvingAgainstBaseURL: false)

        urlComponents?.queryItems = [URLQueryItem(name: "user", value: userID)]

        guard let url = urlComponents?.url else {
            fatalError("Invalid URL components")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey!, forHTTPHeaderField: "api-key")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
                  let responseDict = jsonObject as? [String: Any]
            else {
                print("Failed to parse subscription response")
                return nil
            }

            return responseDict
            
        } catch {
            print("Failed to fetch subscription status: \(error.localizedDescription)")
            return nil
        }
    }
    
    public func hasActiveSubscription(userID: String) async -> Bool {
        
        if let subscriptionStatus = await fetchSubscriptionStatus(userID: userID) {
            
            guard let subscriptions = subscriptionStatus["subscription"] as? [[String: Any]]
            else {
                return false
            }

            let hasActiveSubscription = subscriptions.contains { subscription in
                if let status = subscription["status"] as? String, (status == "active" || status == "trialing") {
                    return true
                }
                return false
            }
            
            return hasActiveSubscription
        }
        return false
    }

    public func fetchSubscriptions(userID: String) async -> [[String: Any]]? {
        
        if let response = await fetchSubscriptionStatus(userID: userID) {
            
            if let subscriptions = response["subscription"] as? [[String: Any]] {
                return subscriptions
            }
        }
        
        return nil
    }

    public func fetchUserProperties(userID: String) async -> [String: String]? {

        assert(nil != apiKey, "You have to initialize apiKey before use")
        
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent("api")
                                                            .appendingPathComponent("user")
                                                            .appendingPathComponent("properties"),
                                          resolvingAgainstBaseURL: false)

        urlComponents?.queryItems = [URLQueryItem(name: "user", value: userID)]

        guard let url = urlComponents?.url else {
            fatalError("Invalid URL components")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey!, forHTTPHeaderField: "api-key")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
                  let responseDict = jsonObject as? [String: Any],
                  let properties = responseDict["properties"] as? [[String: String]]
            else {
                print("Failed to parse properties response")
                return nil
            }

            let resultDict = properties.reduce(into: [String: String]()) { dict, item in
                if let key = item["property"], let value = item["value"] {
                    dict[key] = value
                }
            }
            
            return resultDict
            
        } catch {
            print("Failed to fetch properties: \(error.localizedDescription)")
            return nil
        }
    }

    public func updateUserProperty(userID: String, property: String, value: String) async -> Result<Void, Error> {
        
        assert(nil != apiKey, "You have to initialize apiKey before use")
        
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent("api")
                                                            .appendingPathComponent("user")
                                                            .appendingPathComponent("properties"),
                                          resolvingAgainstBaseURL: false)

        urlComponents?.queryItems = [URLQueryItem(name: "user", value: userID)]

        guard let url = urlComponents?.url else {
            #if DEBUG
            fatalError("Invalid URL components")
            #else
            print("Invalid URL components")
            return .failure(NSError(domain: "Web2WaveError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Invalid URL components"]))
            #endif
        }

        let body = ["property": property, "value": value]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body, options: []) else {
            print("Failed to create JSON data")
            return .failure(NSError(domain: "Web2WaveError", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Failed to create JSON data"]))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey!, forHTTPHeaderField: "api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        request.httpBody = jsonData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                
                guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
                      let responseDict = jsonObject as? [String: Any],
                      let success = responseDict["result"] as? String? else
                {
                    return .failure(NSError(domain: "Web2WaveError", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Smth wrong"]))
                }
                
                if (success == "1") {
                    return .success(())
                }
                else {
                    return .failure(NSError(domain: "Web2WaveError", code: 1004, userInfo: [NSLocalizedDescriptionKey: "Smth wrong"]))
                }
                
            } else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                return .failure(NSError(domain: "Web2WaveError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Unexpected status code: \(statusCode)"]))
            }
            
        } catch {
            return .failure(error)
        }
    }

    public func setRevenuecatProfileID(appUserID: String, revenueCatProfileID: String) async -> Result<Void, Error> {
        return await self.updateUserProperty(userID: appUserID, property: "revenuecat_profile_id", value: revenueCatProfileID)
    }

    public func setAdaptyProfileID(appUserID: String, adaptyProfileID: String) async -> Result<Void, Error> {
        return  await updateUserProperty(userID: appUserID, property: "adapty_profile_id", value: adaptyProfileID)
    }

    public func setQonversionProfileID(appUserID: String, qonversionProfileID: String) async -> Result<Void, Error> {
        return  await updateUserProperty(userID: appUserID, property: "qonversion_profile_id", value: qonversionProfileID)
    }
}
