import SwiftUI
import WebKit

struct WebViewContainer: UIViewRepresentable {
    var onShare: ((String) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "shareReceipt")
        contentController.add(context.coordinator, name: "copyReceipt")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        config.allowsInlineMediaPlayback = true
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0.93, green: 0.95, blue: 0.97, alpha: 1.0)
        webView.scrollView.bounces = true
        webView.navigationDelegate = context.coordinator

        // Native iOS Pull to Refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(context.coordinator, action: #selector(Coordinator.handleRefresh(_:)), for: .valueChanged)
        webView.scrollView.refreshControl = refreshControl

        // Load bundled offline-ready HTML
        if let bundleUrl = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Resources") {
            webView.loadFileURL(bundleUrl, allowingReadAccessTo: bundleUrl.deletingLastPathComponent())
        } else if let flatUrl = Bundle.main.url(forResource: "index", withExtension: "html") {
            webView.loadFileURL(flatUrl, allowingReadAccessTo: flatUrl.deletingLastPathComponent())
        } else {
            // Local fallback host URL
            if let hostUrl = URL(string: "http://127.0.0.1:8000") {
                webView.load(URLRequest(url: hostUrl))
            }
        }

        context.coordinator.webView = webView
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WebViewContainer
        weak var webView: WKWebView?

        init(_ parent: WebViewContainer) {
            self.parent = parent
        }

        @objc func handleRefresh(_ sender: UIRefreshControl) {
            webView?.reload()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                sender.endRefreshing()
            }
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "shareReceipt", let body = message.body as? String {
                parent.onShare?(body)
            } else if message.name == "copyReceipt", let body = message.body as? String {
                UIPasteboard.general.string = body
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.scrollView.refreshControl?.endRefreshing()
        }
    }
}
