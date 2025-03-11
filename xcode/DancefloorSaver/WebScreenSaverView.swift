//
//  WebScreenSaverView.swift
//  Dancefloor Saver
//
//  Created by spencer cap on 1/8/25.
//

import ScreenSaver
import WebKit

//@objc(WebScreenSaverView)
class WebScreenSaverView: ScreenSaverView, WKNavigationDelegate {
    var webView: WKWebView!
    
    // Add this property at the class level
    private var startTime: Date?
    
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
        
        // Configure modern WebKit settings
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        config.defaultWebpagePreferences = preferences
        
        // Configure media autoplay without user interaction
        config.mediaTypesRequiringUserActionForPlayback = []
        
        webView = WKWebView(frame: self.bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.wantsLayer = true
        webView.layer?.backgroundColor = NSColor.white.cgColor
        webView.navigationDelegate = self
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
        // Set the start time when animation begins
        startTime = Date()
    }
    
    override func stopAnimation() {
        NSLog("stopAnimation called")
        super.stopAnimation()
    }
    
    override func animateOneFrame() {
        // Use a more robust JavaScript to keep the WebView active and specifically target Canvas animations
        webView.evaluateJavaScript("""
            window.skeetIt();

            // Basic tick counter
            if (window.screenSaverTickCount === undefined) { 
                window.screenSaverTickCount = 0; 
            }
            window.screenSaverTickCount++;
            
            // Call any custom tick handler
            if (typeof window.screenSaverTick === 'function') {
                window.screenSaverTick(window.screenSaverTickCount);
            }

            // Force Canvas redraw - this is critical for Canvas animations
            const canvases = document.getElementsByTagName('canvas');
            for (let i = 0; i < canvases.length; i++) {
                const canvas = canvases[i];
                const ctx = canvas.getContext('2d') || canvas.getContext('webgl') || canvas.getContext('webgl2');
                if (ctx) {
                    // For 2D canvas
                    if (ctx.getImageData) {
                        // Force a read/write operation on the canvas
                        const imageData = ctx.getImageData(0, 0, 1, 1);
                        ctx.putImageData(imageData, 0, 0);
                    }
                    
                    // For WebGL canvas
                    if (ctx.flush) {
                        ctx.flush();
                    }
                    
                    // Add a tiny transformation to force a redraw
                    if (ctx.save && ctx.restore) {
                        ctx.save();
                        ctx.restore();
                    }
                }
                
                // Force a style change to trigger a repaint
                const currentWidth = canvas.width;
                canvas.width = currentWidth;
            }
            
            
            // Ensure animation frames continue to be requested
            if (window.requestAnimationFrame) {
                window.requestAnimationFrame(function() {
                    // This keeps the animation loop active
                    // For Three.js specifically
                    if (window.renderer && typeof window.renderer.render === 'function') {
                        window.renderer.render(window.scene, window.camera);
                    }
                });
            }
            
            // Force any animation loops to continue
            if (typeof window.animate === 'function') {
                window.animate();
            }
            
            // Force a repaint of the entire document
            document.body.style.minHeight = (document.body.scrollHeight + 0.1) + 'px';
            document.body.style.minHeight = document.body.scrollHeight + 'px';
            
            // Add a timestamp to force DOM updates
            document.body.setAttribute('data-timestamp', Date.now().toString());
            
            true;
        """, completionHandler: nil)
        
        // This is still needed to refresh the screen saver view itself
        setNeedsDisplay(bounds)
    }
    
    // Add this method to ensure the WebView stays active
    override var hasConfigureSheet: Bool {
        return false
    }
    
    // This property helps prevent power-saving mode
    var isPreviewOnly: Bool {
        return false
    }
    
    // Add these delegate methods
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        NSLog("WebView finished loading content")
        // Inject a helper function that your web content can use
        webView.evaluateJavaScript("""
            window.screenSaverTick = function(count) {
                // Your web content can implement this function to respond to animation frames
                // console.log('Screen saver tick: ' + count);
            };
        """, completionHandler: nil)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        NSLog("WebView failed to load: \(error.localizedDescription)")
    }
}
