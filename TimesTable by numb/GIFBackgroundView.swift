import SwiftUI
import WebKit

struct GIFBackgroundView: View {
    let data: Data
    @State private var folderURL: URL?
    @State private var htmlURL: URL?

    var body: some View {
        Group {
            if let htmlURL {
#if os(iOS)
                GIFWebViewiOS(url: htmlURL, directory: folderURL!)
                    .disabled(true)
#else
                GIFWebViewmacOS(url: htmlURL, directory: folderURL!)
                    .disabled(true)
#endif
            } else {
                Color.clear
            }
        }
        .onAppear {
            setupFiles()
        }
        .onDisappear {
            cleanupFiles()
        }
    }

    private func setupFiles() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            let gifURL = tempDir.appendingPathComponent("bg.gif")
            let htmlURL = tempDir.appendingPathComponent("index.html")
            
            try data.write(to: gifURL)
            
            let htmlContent = """
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body {
                        margin: 0;
                        padding: 0;
                        width: 100vw;
                        height: 100vh;
                        background-color: transparent;
                        overflow: hidden;
                        pointer-events: none;
                    }
                    img {
                        width: 100vw;
                        height: 100vh;
                        object-fit: cover;
                    }
                </style>
            </head>
            <body>
                <img src="bg.gif" />
            </body>
            </html>
            """
            try htmlContent.write(to: htmlURL, atomically: true, encoding: .utf8)
            
            self.folderURL = tempDir
            self.htmlURL = htmlURL
        } catch {
            print("Failed to setup GIF files: \(error)")
        }
    }

    private func cleanupFiles() {
        if let folderURL {
            try? FileManager.default.removeItem(at: folderURL)
        }
    }
}

// MARK: - iOS Representation
#if os(iOS)
struct GIFWebViewiOS: UIViewRepresentable {
    let url: URL
    let directory: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadFileURL(url, allowingReadAccessTo: directory)
    }
}
#endif

// MARK: - macOS Representation
#if os(macOS)
struct GIFWebViewmacOS: NSViewRepresentable {
    let url: URL
    let directory: URL

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        nsView.loadFileURL(url, allowingReadAccessTo: directory)
    }
}
#endif
