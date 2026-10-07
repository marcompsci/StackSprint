import Combine
import SwiftUI
import WebKit

// MARK: - Web Runner (WKWebView-based code execution sandbox)

@MainActor final class WebRunner: NSObject, ObservableObject, WKScriptMessageHandler {
    @Published var output: String?
    @Published var isRunning = false

    private var webView: WKWebView?

    override init() {
        super.init()
        let controller = WKUserContentController()
        controller.add(WeakScriptHandler(target: self), name: "result")
        let config = WKWebViewConfiguration()
        config.userContentController = controller
        let wv = WKWebView(frame: .zero, configuration: config)
        webView = wv
        // Load base HTML once — installs console.log interceptor and __run helper
        wv.loadHTMLString(Self.baseHTML, baseURL: nil)
    }

    func run(code: String, language: String) {
        isRunning = true
        output = nil
        let runnable = language == "python" ? transpilePython(code) : code
        guard let jsonData = try? JSONEncoder().encode(runnable),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            output = "Error: could not encode code"
            isRunning = false
            return
        }
        if language == "swift" {
            output = "Swift executes in Studio — tap \"Open hands-on studio\" below."
            isRunning = false
            return
        }
        webView?.evaluateJavaScript("__run(\(jsonString))") { [weak self] result, error in
            Task { @MainActor [weak self] in
                if let result = result as? String {
                    self?.output = result
                } else if let error {
                    self?.output = "Error: \(error.localizedDescription)"
                } else {
                    self?.output = "(no output)"
                }
                self?.isRunning = false
            }
        }
    }

    nonisolated func userContentController(_ ucc: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "result", let body = message.body as? String else { return }
        Task { @MainActor in self.output = body; self.isRunning = false }
    }

    // MARK: Python → JS transpiler (handles common beginner patterns)

    private func transpilePython(_ code: String) -> String {
        var lines = code.components(separatedBy: "\n")
        lines = lines.map { line in
            var l = line
            // Remap # comments
            if let hashIdx = l.firstIndex(of: "#") {
                let before = String(l[l.startIndex..<hashIdx])
                let comment = String(l[hashIdx...])
                l = before + "//" + comment.dropFirst()
            }
            // print() → console.log()
            l = l.replacingOccurrences(of: #"^(\s*)print\("#, with: "$1console.log(", options: .regularExpression)
            return l
        }
        var js = lines.joined(separator: "\n")
        js = js.replacingOccurrences(of: " True", with: " true")
        js = js.replacingOccurrences(of: " False", with: " false")
        js = js.replacingOccurrences(of: " None", with: " null")
        js = js.replacingOccurrences(of: "elif ", with: "else if (")
        js = js.replacingOccurrences(of: "def ", with: "function ")
        return js
    }

    private static let baseHTML = """
    <html><body><script>
    var __lines = [];
    var __origLog = console.log;
    console.log = function() {
        var args = Array.from(arguments).map(function(a) {
            return (typeof a === 'object') ? JSON.stringify(a) : String(a);
        });
        __lines.push(args.join(' '));
        __origLog.apply(console, arguments);
    };
    function __run(code) {
        __lines = [];
        try {
            eval(code);
            return __lines.join('\\n') || '(no output)';
        } catch(e) {
            return 'Error: ' + e.message;
        }
    }
    </script></body></html>
    """
}

// Weak wrapper to avoid WKScriptMessageHandler retain cycle
private final class WeakScriptHandler: NSObject, WKScriptMessageHandler {
    weak var target: (NSObject & WKScriptMessageHandler)?
    init(target: NSObject & WKScriptMessageHandler) { self.target = target }
    func userContentController(_ ucc: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.userContentController(ucc, didReceive: message)
    }
}

// MARK: - Code Runner View

struct CodeRunnerView: View {
    @Binding var code: String
    let language: String
    @StateObject private var runner = WebRunner()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    HapticManager.shared.impact(.light)
                    runner.run(code: code, language: language)
                } label: {
                    Label(runner.isRunning ? "Running…" : "Run ▶", systemImage: runner.isRunning ? "ellipsis" : "play.fill")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 14).padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent).tint(.mint)
                .disabled(runner.isRunning)
                .accessibilityLabel("Run code")
                .accessibilityIdentifier("run-code-button")

                if runner.output != nil {
                    Button("Clear") { runner.output = nil }
                        .font(.subheadline).foregroundStyle(.secondary)
                        .accessibilityLabel("Clear output")
                }
            }

            if let out = runner.output {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Output").font(.caption.bold()).foregroundStyle(.secondary)
                    Text(out)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(out.hasPrefix("Error") ? Color.red : Color.mint)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 10))
                        .textSelection(.enabled)
                        .accessibilityLabel("Code output: \(out)")
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeOut(duration: 0.2), value: runner.output)
            }
        }
    }
}
