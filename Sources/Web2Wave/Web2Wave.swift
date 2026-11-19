//
//  Web2Wave.swift
//  Web2Wave
//
//  Created by Igor Kamenev on 02.11.24.
//

import Foundation
import UIKit

public class Web2Wave: @unchecked Sendable {
    
    public static let shared = Web2Wave()
    
    private let baseURL: URL = URL(string: "https://api.web2wave.com")!
    public var apiKey: String?
    public var urlString: String?
    
    private func getScreenSize() -> String {
        let screen = UIScreen.main.bounds
        return "\(Int(screen.width))x\(Int(screen.height))"
    }
    
    private func getTimezone() -> String {
        let offset = TimeZone.current.secondsFromGMT()
        let totalMinutes = offset / 60
        let hours = totalMinutes / 60
        let minutes = abs(totalMinutes % 60)
        let sign = hours >= 0 ? "+" : "-"
        return String(format: "UTC%@%02d:%02d", sign, abs(hours), minutes)
    }
    
    private func getOSVersion() -> String {
        "iOS \(UIDevice.current.systemVersion)"
    }

    /// Device model / machine id for fingerprinting (e.g. "iPhone15,2").
    private func getDeviceModel() -> String? {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        let identifier = mirror.children.reduce("") { partial, element in
            guard let value = element.value as? Int8, value != 0 else { return partial }
            return partial + String(UnicodeScalar(UInt8(value)))
        }
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
    
    private func applyFingerprintHeaders(to request: inout URLRequest) {
        request.setValue(apiKey!, forHTTPHeaderField: "api-key")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        request.setValue("iOS", forHTTPHeaderField: "platform")
        request.setValue(getScreenSize(), forHTTPHeaderField: "screen_size")
        request.setValue(getTimezone(), forHTTPHeaderField: "timezone")
        request.setValue(getOSVersion(), forHTTPHeaderField: "os_version")
        if let deviceModel = getDeviceModel() {
            request.setValue(deviceModel, forHTTPHeaderField: "device_model")
        }
    }
    
    /// Extracts the server's error text from an error body (`{"error":1,"error_msg":"..."}`),
    /// falling back to `message`, then to a generic status-code message.
    private func apiErrorMessage(from data: Data, statusCode: Int) -> String {
        if let dict = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] {
            if let msg = dict["error_msg"] as? String, !msg.isEmpty { return msg }
            if let msg = dict["message"] as? String, !msg.isEmpty { return msg }
        }
        return "Unexpected status code: \(statusCode)"
    }

    /// Builds an `NSError` in the `Web2WaveError` domain carrying the server's error text.
    /// `userInfo["required_scope"]` is set when the API key lacks a scope (HTTP 403).
    private func apiError(from data: Data, statusCode: Int, code: Int) -> NSError {
        var userInfo: [String: Any] = [NSLocalizedDescriptionKey: apiErrorMessage(from: data, statusCode: statusCode)]
        if let dict = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any],
           let scope = dict["required_scope"] as? String {
            userInfo["required_scope"] = scope
        }
        return NSError(domain: "Web2WaveError", code: code, userInfo: userInfo)
    }

    private func isSuccessStatus(_ response: URLResponse) -> Bool {
        guard let http = response as? HTTPURLResponse else { return false }
        return (200..<300).contains(http.statusCode)
    }

    private func statusCode(of response: URLResponse) -> Int {
        (response as? HTTPURLResponse)?.statusCode ?? 0
    }

    public func identify() async -> [String: Any]? {
        assert(nil != apiKey, "You have to initialize apiKey before use")
        
        let url = baseURL.appendingPathComponent("api")
            .appendingPathComponent("user")
            .appendingPathComponent("identify")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyFingerprintHeaders(to: &request)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Failed to identify user: \(apiErrorMessage(from: data, statusCode: statusCode(of: response)))")
                return nil
            }
            
            guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
                  let responseDict = jsonObject as? [String: Any]
            else {
                print("Failed to parse identify response")
                return nil
            }
            
            return responseDict
        } catch {
            print("Failed to identify user: \(error.localizedDescription)")
            return nil
        }
    }
    
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
        applyFingerprintHeaders(to: &request)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if !isSuccessStatus(response) {
                print("Failed to fetch subscription status: \(apiErrorMessage(from: data, statusCode: statusCode(of: response)))")
            }
            
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
        applyFingerprintHeaders(to: &request)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Error bodies ({"error":1,"error_msg":...}, e.g. 403 missing scope or 422 user not found)
            // used to decode as an empty property list; report them as a failure instead.
            guard isSuccessStatus(response) else {
                print("Failed to fetch properties: \(apiErrorMessage(from: data, statusCode: statusCode(of: response)))")
                return nil
            }
            
            let decodedResponse = try JSONDecoder().decode(PropertiesResponse.self, from: data)
            let resultDict = decodedResponse.properties.reduce(into: [String: String]()) { dict, item in
                dict[item.key] = item.value ?? ""
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
        applyFingerprintHeaders(to: &request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            let code = statusCode(of: response)
            guard isSuccessStatus(response) else {
                // Surface the server's error_msg (e.g. a 403 when the API key lacks the required scope).
                return .failure(apiError(from: data, statusCode: code, code: code))
            }
            
            guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
                  let responseDict = jsonObject as? [String: Any] else
            {
                return .failure(NSError(domain: "Web2WaveError", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"]))
            }
            
            let result = responseDict["result"]
            let isSuccess = (result as? String) == "1" || (result as? NSNumber)?.intValue == 1
            if isSuccess {
                return .success(())
            }
            return .failure(apiError(from: data, statusCode: code, code: 1004))
            
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
    
    public func setApphudProfileID(web2waveUserId: String, apphudProfileID: String) async -> Result<Void, Error> {
        return await updateUserProperty(web2waveUserId: web2waveUserId, property: "apphud_profile_id", value: apphudProfileID)
    }
    
    public func setSuperwallProfileID(web2waveUserId: String, superwallProfileID: String) async -> Result<Void, Error> {
        return await updateUserProperty(web2waveUserId: web2waveUserId, property: "superwall_profile_id", value: superwallProfileID)
    }
    
    @MainActor public func showWebView(currentVC: UIViewController?, urlString: String, topOffset: CGFloat = 0, bottomOffset: CGFloat = 0, delegate: Web2WaveWebListener, backgroundColor: UIColor? = nil) {
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
        
        let webViewController = WebViewVC(delegate: delegate, urlStr: finalUrlString, backgroundColor: backgroundColor)
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
