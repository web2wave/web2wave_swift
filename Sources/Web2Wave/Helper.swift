//
//  Helper.swift
//  Web2Wave
//
//  Created by Mina Djuric on 19.8.25..
//

import UIKit

public protocol Web2WaveWebListener: AnyObject {
    func onEvent(event: String, data: [String: Any]?)
    func onClose(data: [String: Any]?)
    func onQuizFinished(data: [String: Any]?)
}

public enum Web2WaveEvent: String {
    case closeWebview = "Close webview"
    case pageClosed = "Page closed"
    case quizFinished = "Quiz finished"
}

struct Property: Decodable {
    let key: String
    let value: String?

    enum CodingKeys: String, CodingKey {
        case property, value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decode(String.self, forKey: .property)
        value = try? container.decode(String.self, forKey: .value)
    }
}

struct PropertiesResponse: Decodable {
    let properties: [Property]
    
    enum CodingKeys: String, CodingKey {
        case properties
        case property
    }
    
    init(from decoder: Decoder) throws {
        let container = try? decoder.container(keyedBy: CodingKeys.self)
        
        if let container = container,
           let props = try? container.decode([Property].self, forKey: .properties) {
            properties = props
            return
        }
        if let container = container,
           let single = try? container.decode(Property.self, forKey: .property) {
            properties = [single]
            return
        }
        if let single = try? Property(from: decoder) {
            properties = [single]
            return
        }
        properties = []
    }
}

struct Headers {
    static func screenSize() -> String {
        let size = UIScreen.main.nativeBounds.size

        let width = Int(size.width)
        let height = Int(size.height)
        return "\(width)x\(height)"
    }
    
    static func timezone() -> String {
        let tz = TimeZone.current
        let seconds = tz.secondsFromGMT()
        let sign = seconds >= 0 ? "+" : "-"
        let absSeconds = abs(seconds)
        let hours = absSeconds / 3600
        let minutes = (absSeconds % 3600) / 60
        return String(format: "UTC%@%02d:%02d", sign, hours, minutes)
    }
}
