//
//  WebScreenSaverView.swift
//  Dancefloor Saver
//
//  Created by spencer cap on 1/8/25.
//

import ScreenSaver
import WebKit

// MARK: - Shared WebView Manager
// Single shared WebView to prevent multiple Web Content processes
// WKWebView processes are managed by the system and hard to terminate,
// so we use ONE WebView that persists and gets reused across all instances
private class SharedWebViewManager {
    static let shared = SharedWebViewManager()
    
    let webView: WKWebView
    private let processPool = WKProcessPool()
    var isContentLoaded = false
    var currentOwner: WebScreenSaverView? // Track which view is currently using the webView
    
    private init() {
        let config = WKWebViewConfiguration()
        config.setValue(true, forKey: "_allowUniversalAccessFromFileURLs")
        config.processPool = processPool
        
        // Use non-persistent data store to reduce memory
        config.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        config.defaultWebpagePreferences = preferences
        config.mediaTypesRequiringUserActionForPlayback = []
        
        webView = WKWebView(frame: .zero, configuration: config)
        webView.wantsLayer = true
        webView.layer?.backgroundColor = NSColor.black.cgColor
        webView.setValue(false, forKey: "drawsBackground")
        
        NSLog("SharedWebViewManager: Created shared WebView")
    }
    
    func loadContentIfNeeded(bundle: Bundle) {
        guard !isContentLoaded else { 
            NSLog("SharedWebViewManager: Content already loaded, resuming")
            webView.evaluateJavaScript("if (typeof window.resume === 'function') { window.resume(); }", completionHandler: nil)
            return 
        }
        
        if let htmlPath = bundle.path(forResource: "index", ofType: "html") {
            let url = URL(fileURLWithPath: htmlPath)
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            isContentLoaded = true
            NSLog("SharedWebViewManager: Loading content from \(htmlPath)")
        } else {
            NSLog("SharedWebViewManager: Failed to find index.html")
            webView.loadHTMLString("<html><body style='background: red;'><h2>couldn't find local HTML</h2></body></html>", baseURL: nil)
        }
    }
    
    func pause() {
        webView.evaluateJavaScript("if (typeof window.pause === 'function') { window.pause(); }", completionHandler: nil)
        NSLog("SharedWebViewManager: Paused")
    }
    
    func resume() {
        webView.evaluateJavaScript("if (typeof window.resume === 'function') { window.resume(); }", completionHandler: nil)
        NSLog("SharedWebViewManager: Resumed")
    }
}

//@objc(WebScreenSaverView)
class WebScreenSaverView: ScreenSaverView, WKNavigationDelegate {
    // Reference to the shared WebView (not owned by this instance)
    private var webView: WKWebView? {
        return SharedWebViewManager.shared.webView
    }
    
    // Add this property at the class level
    private var startTime: Date?
    
    // FPS tracking for Swift layer
    private var swiftFrameCount: Int = 0
    private var swiftLastFPSTime: Date = Date()
    private var swiftFPS: Double = 0
    private var swiftFPSLabel: NSTextField!
    
    // Configuration
    private var configSheet: NSWindow?
    private var showFPSCheckbox: NSButton?
    
    // Defaults for preferences
    private var defaults: ScreenSaverDefaults? {
        return ScreenSaverDefaults(forModuleWithName: Bundle(for: type(of: self)).bundleIdentifier ?? "com.dancefloor.saver")
    }
    
    private var showFPS: Bool {
        get { defaults?.bool(forKey: "showFPS") ?? true }
        set {
            defaults?.set(newValue, forKey: "showFPS")
            defaults?.synchronize()
        }
    }
    
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        
        NSLog("WebScreenSaverView initialized with frame: \(frame), isPreview: \(isPreview)")
        
        // Basic setup
        animationTimeInterval = 1/60.0
        wantsLayer = true
        layer?.backgroundColor = .black
        
        // Create Swift FPS label (top-right corner)
        swiftFPSLabel = NSTextField(labelWithString: "Swift FPS: --")
        swiftFPSLabel.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        swiftFPSLabel.textColor = NSColor.cyan
        swiftFPSLabel.backgroundColor = NSColor(white: 0, alpha: 0.7)
        swiftFPSLabel.drawsBackground = true
        swiftFPSLabel.isBezeled = false
        swiftFPSLabel.isEditable = false
        swiftFPSLabel.wantsLayer = true
        swiftFPSLabel.layer?.zPosition = 1000
        swiftFPSLabel.sizeToFit()
        swiftFPSLabel.frame = NSRect(x: frame.width - 150,
                                      y: frame.height - 30,
                                      width: 140,
                                      height: 20)
        swiftFPSLabel.isHidden = !showFPS
        addSubview(swiftFPSLabel)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layout() {
        super.layout()
        // Reposition FPS label when view resizes (e.g., going fullscreen)
        if let label = swiftFPSLabel {
            label.frame = NSRect(x: bounds.width - 150,
                                  y: bounds.height - 30,
                                  width: 140,
                                  height: 20)
            // Bring label to front by re-adding it
            label.removeFromSuperview()
            addSubview(label, positioned: .above, relativeTo: webView)
        }
    }
    
    override func draw(_ rect: NSRect) {
        NSLog("draw called")
        
        // Draw a simple background
        NSColor.black.setFill()
        bounds.fill()

        webView?.setNeedsDisplay(rect)
    }
    
    override func startAnimation() {
        NSLog("startAnimation called")
        super.startAnimation()
        
        startTime = Date()
        
        let manager = SharedWebViewManager.shared
        
        // Take ownership of the shared WebView
        manager.currentOwner = self
        
        // Add the shared WebView to our view hierarchy
        if let wv = webView {
            wv.frame = self.bounds
            wv.autoresizingMask = [.width, .height]
            wv.navigationDelegate = self
            
            // Remove from previous superview if any
            wv.removeFromSuperview()
            addSubview(wv)
            
            // Ensure FPS label is on top
            if let label = swiftFPSLabel {
                label.removeFromSuperview()
                addSubview(label, positioned: .above, relativeTo: wv)
            }
        }
        
        // Load content if needed, or resume if already loaded
        manager.loadContentIfNeeded(bundle: Bundle(for: type(of: self)))
    }
    
    override func stopAnimation() {
        NSLog("stopAnimation called")
        super.stopAnimation()
        
        let manager = SharedWebViewManager.shared
        
        // Only pause if we're the current owner
        if manager.currentOwner === self {
            manager.pause()
            manager.currentOwner = nil
            
            // Remove webView from our hierarchy (but don't destroy it)
            webView?.removeFromSuperview()
        }
    }
    
    override func removeFromSuperview() {
        NSLog("removeFromSuperview called")
        
        // Release ownership if we have it
        if SharedWebViewManager.shared.currentOwner === self {
            SharedWebViewManager.shared.pause()
            SharedWebViewManager.shared.currentOwner = nil
        }
        
        super.removeFromSuperview()
    }
    
    deinit {
        NSLog("WebScreenSaverView deinit called")
        
        // Release ownership if we have it
        if SharedWebViewManager.shared.currentOwner === self {
            SharedWebViewManager.shared.pause()
            SharedWebViewManager.shared.currentOwner = nil
        }
        
        configSheet = nil
    }
    
    override func animateOneFrame() {
        // Skip if not animating or we're not the owner
        guard isAnimating, 
              SharedWebViewManager.shared.currentOwner === self,
              webView != nil else { return }
        
        // FPS tracking for Swift layer
        swiftFrameCount += 1
        let now = Date()
        let elapsed = now.timeIntervalSince(swiftLastFPSTime)
        if elapsed >= 1.0 {
            swiftFPS = Double(swiftFrameCount) / elapsed
            swiftFPSLabel.stringValue = String(format: "Swift FPS: %.1f", swiftFPS)
            swiftFrameCount = 0
            swiftLastFPSTime = now
        }
        
        // Call the exposed tick function directly - this renders one frame of the Three.js scene
        // The tick function is exposed on window in index.html and handles all animation logic
        webView?.evaluateJavaScript("if (typeof window.tick === 'function') { window.tick(); }", completionHandler: nil)
        
        // Refresh the screen saver view
        setNeedsDisplay(bounds)
    }
    
    // MARK: - Configuration Sheet
    
    override var hasConfigureSheet: Bool {
        return true
    }
    
    override var configureSheet: NSWindow? {
        if configSheet == nil {
            configSheet = createConfigSheet()
        }
        return configSheet
    }
    
    private func createConfigSheet() -> NSWindow {
        let sheet = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 120),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        sheet.title = "Dancefloor Saver Options"
        
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 120))
        
        // Show FPS checkbox
        showFPSCheckbox = NSButton(checkboxWithTitle: "Show FPS Counters", target: self, action: #selector(fpsCheckboxChanged(_:)))
        showFPSCheckbox?.frame = NSRect(x: 20, y: 70, width: 200, height: 20)
        showFPSCheckbox?.state = showFPS ? .on : .off
        contentView.addSubview(showFPSCheckbox!)
        
        // OK button
        let okButton = NSButton(title: "OK", target: self, action: #selector(closeConfigSheet(_:)))
        okButton.frame = NSRect(x: 200, y: 20, width: 80, height: 30)
        okButton.bezelStyle = .rounded
        okButton.keyEquivalent = "\r"
        contentView.addSubview(okButton)
        
        // Cancel button
        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancelConfigSheet(_:)))
        cancelButton.frame = NSRect(x: 110, y: 20, width: 80, height: 30)
        cancelButton.bezelStyle = .rounded
        cancelButton.keyEquivalent = "\u{1b}"
        contentView.addSubview(cancelButton)
        
        sheet.contentView = contentView
        return sheet
    }
    
    @objc private func fpsCheckboxChanged(_ sender: NSButton) {
        // Just update the checkbox state, actual save happens on OK
    }
    
    @objc private func closeConfigSheet(_ sender: NSButton) {
        // Save the setting
        showFPS = showFPSCheckbox?.state == .on
        
        // Apply to Swift label
        swiftFPSLabel?.isHidden = !showFPS
        
        // Apply to JS FPS display via body class
        let fpsClass = showFPS ? "fps-visible" : "fps-hidden"
        webView?.evaluateJavaScript("document.body.classList.remove('fps-visible', 'fps-hidden'); document.body.classList.add('\(fpsClass)');", completionHandler: nil)
        
        // Close sheet
        if let sheet = configSheet {
            window?.endSheet(sheet)
        }
    }
    
    @objc private func cancelConfigSheet(_ sender: NSButton) {
        // Reset checkbox to saved value
        showFPSCheckbox?.state = showFPS ? .on : .off
        
        // Close sheet
        if let sheet = configSheet {
            window?.endSheet(sheet)
        }
    }
    
    // This property helps prevent power-saving mode
    var isPreviewOnly: Bool {
        return false
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        NSLog("WebView finished loading content")
        // Apply FPS visibility setting to JS via body class
        let fpsClass = showFPS ? "fps-visible" : "fps-hidden"
        webView.evaluateJavaScript("document.body.classList.remove('fps-visible', 'fps-hidden'); document.body.classList.add('\(fpsClass)');", completionHandler: nil)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        NSLog("WebView failed to load: \(error.localizedDescription)")
    }
}
