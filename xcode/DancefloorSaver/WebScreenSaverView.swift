//
//  WebScreenSaverView.swift
//  Dancefloor Saver
//
//  Created by spencer cap on 1/8/25.
//

import ScreenSaver
import WebKit

//@objc(WebScreenSaverView)
class WebScreenSaverView: ScreenSaverView {
    var webView: WKWebView!
    
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        print("WebScreenSaverView init")  // This won't show in Console.app
        
        // Try using NSLog which will show in Console.app
        NSLog("WebScreenSaverView initialized with frame: \(frame)")
        
        // Basic setup
        animationTimeInterval = 1/30.0

        // more
        wantsLayer = true
        layer?.backgroundColor = .black  // Add this to see the base layer
        
        let config = WKWebViewConfiguration()
        config.setValue(true, forKey: "_allowUniversalAccessFromFileURLs")
        
        webView = WKWebView(frame: self.bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.wantsLayer = true  // Add this
        webView.layer?.backgroundColor = NSColor.white.cgColor  // Add this to make WebView visible
        addSubview(webView)
        
        // Add this debug content to test if WebView is working
        // webView.loadHTMLString("<html><body style='background: green;'><h1>bewm!</h1></body></html>", baseURL: nil)
        
        // from HTML file
        if let htmlPath = Bundle(for: type(of: self)).path(forResource: "index", ofType: "html") {
           let url = URL(fileURLWithPath: htmlPath)
           webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            NSLog("Failed to find index.html")
            webView.loadHTMLString("<html><body style='background: red;'><h2>couldnt find local HTML</h2></body></html>", baseURL: nil)
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ rect: NSRect) {
        NSLog("draw called")
        
        // Draw a simple background
        NSColor.blue.setFill()
        bounds.fill()

        webView.setNeedsDisplay(rect)
    }
    
    override func startAnimation() {
        NSLog("startAnimation called")
        super.startAnimation()
    }
    
    override func stopAnimation() {
        NSLog("stopAnimation called")
        super.stopAnimation()
    }
    
    override func animateOneFrame() {
        // Remove or comment out this log as it will flood your console
        // NSLog("animateOneFrame called")
        
        // Instead of just calling setNeedsDisplay, we need to ensure the WebView
        // continues to process its JavaScript and render updates
        webView.evaluateJavaScript("1+1", completionHandler: nil)
        
        // This is still needed to refresh the screen saver view itself
        setNeedsDisplay(bounds)
    }
}
