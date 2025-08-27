//
//  Helper.swift
//  Web2Wave
//
//  Created by Mina Djuric on 19.8.25..
//

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
