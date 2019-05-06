//
//  EmbedFrameworkView.swift
//  EmbedFramework
//
//  Created by Nicholas Haley on 2019-04-23.
//  Copyright © 2019 Ada Support. All rights reserved.
//

import UIKit
import WebKit

internal class EmbedView: UIView, WKNavigationDelegate, WKScriptMessageHandler {
    
    var webView: WKWebView!
    var handle: String
    var cluster: String
    var language: String
    var styles: String
    var greeting: String
    var metaFields: [String: String]
    
    let html = """
        <html>
          <head>
            <meta charset="UTF-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            </head>
            <body style="height: 100vh; margin: 0;">
                <div id="parent-element" style="height: 100vh; width: 100vw;"></div>
            </body>
            <script>
                window.adaSettings = {
                    parentElement: "parent-element"
                }
            </script>
            <script
                async
                id="__ada"
                src="https://static.ada.support/embed.js"
                data-lazy
                onload="onLoadHandler()"
            ></script>
            <script>
                function onLoadHandler() {
                    // Tell framework Embed is ready
                    try {
                        window.webkit.messageHandlers.embedReady.postMessage("ready");
                    } catch(err) {
                        console.error("Can not reach native code");
                    }
                }

                function initializeEmbed(data) {
                    const decodedData = window.atob(data)
                    const parsedData = JSON.parse(decodedData)
                    const { handle, cluster, language, styles, greeting, metaFields } = parsedData;

                    adaEmbed.start({
                        handle,
                        parentElement: "parent-element",
                        cluster,
                        language,
                        styles,
                        greeting,
                        metaFields
                    });
                }

                function setMetaFields(data) {
                    const decodedData = window.atob(data)
                    const parsedData = JSON.parse(decodedData)

                    adaEmbed.setMetaFields(parsedData);
                }
            </script>
        </html>

    """
    
    internal init(
        frame: CGRect,
        handle: String,
        cluster: String,
        language: String,
        styles: String,
        greeting: String,
        metaFields: [String: String]
    ) {
        self.handle = handle
        self.cluster = cluster
        self.language = language
        self.styles = styles
        self.greeting = greeting
        self.metaFields = metaFields
        
        super.init(frame: frame)
        setUpView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUpView() {
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        
        userContentController.add(self, name: "embedReady")
        
        config.userContentController = userContentController

        webView = WKWebView(frame: self.frame, configuration: config)
        addSubview(webView)
        
        // This isn't working yet :(
//        let bundle = Bundle.init(identifier: "com.ada.EmbedFramework")
//        print(bundle as Any)
//        if let htmlPath = bundle?.path(forResource: "index", ofType: "html") {
//            let url = URL(fileURLWithPath: htmlPath)
//            let request = URLRequest(url: url)
//            webView.load(request)
//        }

        webView.loadHTMLString(html, baseURL: nil)
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("PM: \(message.name), \(message.body) ")
        if message.name == "embedReady" {
            self.initialize()
        }
    }
    
    private func initialize() {
        let serializedData = try! JSONSerialization.data(withJSONObject: [
            "handle": self.handle,
            "cluster": self.cluster,
            "language": self.language,
            "styles": self.styles,
            "greeting": self.greeting,
            "metaFields": self.metaFields
            ], options: [])
        let encodedData = serializedData.base64EncodedString()
        
        self.webView.evaluateJavaScript("initializeEmbed('\(encodedData)');") { (result, error) in
            if let err = error {
                print(err)
                print(err.localizedDescription)
            } else {
                guard let dataValue = result else {return}
                print(dataValue)
            }
        }
    }
}
