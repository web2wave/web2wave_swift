//
//  WebViewVC.swift
//  Web2Wave
//
//  Created by Mina Djuric on 18.8.25..
//

import Foundation
import WebKit

class WebViewVC: UIViewController {
    
    public var urlStr: String = ""
    public weak var delegate: Web2WaveWebListener?
    private var backgroundColor: UIColor?
    
    private var webView: WKWebView!
            
    init(delegate: Web2WaveWebListener, urlStr: String, backgroundColor: UIColor?) {
        super.init(nibName: nil, bundle: nil)
        self.delegate = delegate
        self.urlStr = urlStr
        self.backgroundColor = backgroundColor
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
        self.setupWebView()
        self.navigationItem.hidesBackButton = true
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    private func getWKWebViewConfiguration() -> WKWebViewConfiguration {
        let userController = WKUserContentController()
        
        userController.add(self, name: "iosListener")
        
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        configuration.userContentController = userController
        return configuration
    }
    
    private func setupWebView() {
        webView = WKWebView(frame: .zero, configuration: self.getWKWebViewConfiguration())
        webView.navigationDelegate = self
        
        if let backgroundColor = backgroundColor {
            webView.backgroundColor = backgroundColor
            webView.isOpaque = false
        }
        
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        self.loadPage()
    }
    
    private func loadPage() {
        webView.scrollView.decelerationRate = .normal
        guard let url: URL = URL(string: urlStr) else { return }
        
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

extension WebViewVC: WKNavigationDelegate, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("Received message: \(message.body)")

        if message.name == "iosListener", let messageBody = message.body as? String {
            
            if let data = messageBody.data(using: .utf8) {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        guard let event = json["event"] as? String else { return }
                        let eventData = json["data"] as? [String: Any]
                        switch event {
                        case Web2WaveEvent.closeWebview.rawValue, Web2WaveEvent.pageClosed.rawValue:
                            delegate?.onClose(data: eventData)
                        case Web2WaveEvent.quizFinished.rawValue:
                            delegate?.onQuizFinished(data: eventData)
                        default:
                            delegate?.onEvent(event: event, data: eventData)
                        }
                    }
                }
                catch {
                    print("Error parsing JSON: \(error)")
                }
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("WebView did finish loading.")
        webView.isOpaque = true
    }
}
