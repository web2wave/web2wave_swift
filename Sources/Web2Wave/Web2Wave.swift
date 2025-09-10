//
//  Web2Wave.swift
//  Web2Wave
//
//  Created by Igor Kamenev on 02.11.24.
//

import Foundation
import AppsFlyerLib
import RevenueCat
import UIKit

public class Web2Wave: NSObject, @unchecked Sendable  {
    
    public static let shared = Web2Wave()
    
    private let baseURL: URL = URL(string: "https://api.web2wave.com")!
    public var apiKey: String?
    private var onFailure: ((String) -> Void)?
    private var onSuccess: ((String) -> Void)?
    
    public func fetchSubscriptionStatus(web2waveUserId: String) async -> [String: Any]? {
        
        assert(nil != apiKey, "You have to initialize apiKey before use")
        
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent("api")
            .appendingPathComponent("user")
            .appendingPathComponent("subscriptions"),
                                          resolvingAgainstBaseURL: false)
        
        urlComponents?.queryItems = [URLQueryItem(name: "user", value: web2waveUserId)]
        
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
    
    public func hasActiveSubscription(web2waveUserId: String) async -> Bool {
        
        if let subscriptionStatus = await fetchSubscriptionStatus(web2waveUserId: web2waveUserId) {
            
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
    
    public func fetchSubscriptions(web2waveUserId: String) async -> [[String: Any]]? {
        
        if let response = await fetchSubscriptionStatus(web2waveUserId: web2waveUserId) {
            
            if let subscriptions = response["subscription"] as? [[String: Any]] {
                return subscriptions
            }
        }
        
        return nil
    }
    
    public func fetchUserProperties(web2waveUserId: String) async -> [String: String]? {
        
        assert(nil != apiKey, "You have to initialize apiKey before use")
        
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent("api")
            .appendingPathComponent("user")
            .appendingPathComponent("properties"),
                                          resolvingAgainstBaseURL: false)
        
        urlComponents?.queryItems = [URLQueryItem(name: "user", value: web2waveUserId)]
        
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
    
    public func updateUserProperty(web2waveUserId: String, property: String, value: String) async -> Result<Void, Error> {
        
        assert(nil != apiKey, "You have to initialize apiKey before use")
        
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent("api")
            .appendingPathComponent("user")
            .appendingPathComponent("properties"),
                                          resolvingAgainstBaseURL: false)
        
        urlComponents?.queryItems = [URLQueryItem(name: "user", value: web2waveUserId)]
        
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
    
    public func setRevenuecatProfileID(web2waveUserId: String, revenueCatProfileID: String) async -> Result<Void, Error> {
        return await self.updateUserProperty(web2waveUserId: web2waveUserId, property: "revenuecat_profile_id", value: revenueCatProfileID)
    }
    
    public func setAdaptyProfileID(web2waveUserId: String, adaptyProfileID: String) async -> Result<Void, Error> {
        return  await updateUserProperty(web2waveUserId: web2waveUserId, property: "adapty_profile_id", value: adaptyProfileID)
    }
    
    public func setQonversionProfileID(web2waveUserId: String, qonversionProfileID: String) async -> Result<Void, Error> {
        return  await updateUserProperty(web2waveUserId: web2waveUserId, property: "qonversion_profile_id", value: qonversionProfileID)
    }
    
    @MainActor public func showWebView(currentVC: UIViewController?, urlString: String, topOffset: CGFloat = 0, bottomOffset: CGFloat = 0, delegate: Web2WaveWebListener) {
        guard let currentVC = currentVC else { return }
        
        var components = URLComponents(string: urlString)
        var queryItems = components?.queryItems ?? []
        queryItems.append(contentsOf: [
            URLQueryItem(name: "webview_ios", value: "1"),
            URLQueryItem(name: "top_padding", value: "\(Int(topOffset))"),
            URLQueryItem(name: "bottom_padding", value: "\(Int(bottomOffset))")
        ])
        components?.queryItems = queryItems
        guard let finalUrlString = components?.url?.absoluteString else { return }
        
        let webViewController = WebViewVC(delegate: delegate, urlStr: finalUrlString)
        webViewController.modalPresentationStyle = .fullScreen
        if let navController = currentVC.navigationController {
            navController.pushViewController(webViewController, animated: true)
        } else {
            webViewController.modalPresentationStyle = .fullScreen
            currentVC.present(webViewController, animated: true)
        }
    }
    
    @MainActor public func closeWebView(currentVC: UIViewController?) {
        guard let currentVC = currentVC else { return }
        if let navController = currentVC.navigationController {
            navController.popViewController(animated: true)
        } else {
            currentVC.dismiss(animated: true)
        }
    }
}

//MARK: AppsFlyer setup
extension Web2Wave: DeepLinkDelegate {
    public func setupAppsFlyerLib(revenuecatPublicApiKey: String?, appleAppID: String?, appsFlyerDevKey: String?, onSuccess: @escaping (String) -> Void, onFailure: @escaping (String) -> Void) {
        self.onSuccess = onSuccess
        self.onFailure = onFailure
        
        guard let appleAppID = appleAppID, let appsFlyerDevKey = appsFlyerDevKey,  let revenuecatPublicApiKey = revenuecatPublicApiKey else {
            print("Missing required parameter for AppsFlyer setup")
            self.onFailure?("Missing required parameter for AppsFlyer setup")
            return
        }
        
        AppsFlyerLib.shared().appsFlyerDevKey = appsFlyerDevKey
        AppsFlyerLib.shared().appleAppID = appleAppID
        
        Purchases.configure(withAPIKey: revenuecatPublicApiKey)
        AppsFlyerLib.shared().deepLinkDelegate = self
        
        AppsFlyerLib.shared().start()
        
    }
    
    // MARK: - DeepLinkDelegate
    /// Called when AppsFlyer resolves a deep link.
    public func didResolveDeepLink(_ result: DeepLinkResult) {
        if case .found = result.status, let deepLink = result.deepLink {
            handleDeepLink(deepLink)
        } else {
            let errorMessage = result.error?.localizedDescription ?? "Deep link not found"
            onFailure?(errorMessage)
        }
    }
    
    private func handleDeepLink(_ deepLink: DeepLink) {
        guard let deepLinkValue = deepLink.deeplinkValue,
              let userData = deepLinkValue.data(using: .utf8),
              let userDict = try? JSONSerialization.jsonObject(with: userData) as? [String: Any],
              let extractedUserId = userDict["user_id"] as? String else {
            print("Failed to parse deep_link_value")
            onFailure?("Failed to parse deep_link_value")
            return
        }
        print("User ID from deep link: \(extractedUserId)")
        fetchRevenueCatAppUserID(userId: extractedUserId)
    }
    
    private func fetchRevenueCatAppUserID(userId: String) {
        let appUserID = Purchases.shared.appUserID
        print("RevenueCat App User ID: \(appUserID)")
        Task {
            await self.sendAppUserIDToWeb2Wave(userId, appUserID)
        }
    }
    
    private func sendAppUserIDToWeb2Wave(_ userId: String, _ appUserID: String) async {
        switch await Web2Wave.shared.setRevenuecatProfileID(web2waveUserId: userId, revenueCatProfileID: appUserID) {
        case .success:
            print("Successfully sent RevenueCat ID to Web2Wave API")
            onSuccess?("Successfully sent RevenueCat ID to Web2Wave API")
        case .failure(let error):
            print("Error sending data to Web2Wave API: \(error)")
            onFailure?("Error sending data to Web2Wave API: \(error)")
        }
    }
}
