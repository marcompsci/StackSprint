import SwiftUI
import UIKit
import WebKit

// MARK: - Tactile "key cap" buttons
//
// Every Studio button is a physical key: a raised face sitting on a darker lip.
// Pressing pushes the face down onto the lip, with a light haptic tap. Labels
// never wrap, so a button can't collapse into one letter per line.

enum StudioKeyRole { case primary, secondary, quiet, icon }

struct StudioKeyStyle: ButtonStyle {
    var role: StudioKeyRole = .secondary
    var tint: Color = .mint
    /// Stretch across the row (for big call-to-action buttons).
    var fullWidth = false

    func makeBody(configuration: Configuration) -> some View {
        StudioKey(configuration: configuration, role: role, tint: tint, fullWidth: fullWidth)
    }
}

extension ButtonStyle where Self == StudioKeyStyle {
    static var studioPrimary: StudioKeyStyle { StudioKeyStyle(role: .primary) }
    static var studioSecondary: StudioKeyStyle { StudioKeyStyle(role: .secondary) }
    static var studioQuiet: StudioKeyStyle { StudioKeyStyle(role: .quiet) }
    static var studioIcon: StudioKeyStyle { StudioKeyStyle(role: .icon) }
    static func studioKey(_ role: StudioKeyRole, tint: Color = .mint, fullWidth: Bool = false) -> StudioKeyStyle {
        StudioKeyStyle(role: role, tint: tint, fullWidth: fullWidth)
    }
}

private struct StudioKey: View {
    let configuration: ButtonStyleConfiguration
    let role: StudioKeyRole
    let tint: Color
    let fullWidth: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var depth: CGFloat { isEnabled ? (role == .quiet ? 3 : 5) : 2 }
    private var pressed: Bool { configuration.isPressed && isEnabled }
    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: role == .icon ? 13 : 15, style: .continuous) }

    var body: some View {
        let travel: CGFloat = pressed ? depth - 1 : 0
        face
            // The lip is sized to the face and held still while the face
            // travels down onto it.
            .background { shape.fill(lipColor).offset(y: depth - travel) }
            .offset(y: travel)
            .padding(.bottom, depth)
        .shadow(color: glowColor, radius: pressed ? 3 : 10, y: pressed ? 1 : 4)
        .animation(reduceMotion ? nil : .spring(response: 0.16, dampingFraction: 0.62), value: pressed)
        .sensoryFeedback(.impact(weight: .light, intensity: 0.8), trigger: configuration.isPressed) { _, isDown in isDown && isEnabled }
        .contentShape(shape)
    }

    private var face: some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .lineLimit(1)
            .fixedSize(horizontal: !fullWidth, vertical: false)
            .minimumScaleFactor(fullWidth ? 0.8 : 1)
            .foregroundStyle(labelColor)
            .padding(.horizontal, role == .icon ? 14 : 18)
            .frame(minWidth: 44, maxWidth: fullWidth ? .infinity : nil, minHeight: fullWidth ? 52 : 44)
            .background {
                ZStack {
                    shape.fill(faceColor)
                    // Soft top highlight sells the raised, glossy key.
                    shape.fill(LinearGradient(colors: [.white.opacity(isEnabled ? 0.22 : 0.06), .clear],
                                              startPoint: .top, endPoint: .center))
                }
            }
            .overlay(shape.strokeBorder(rimColor, lineWidth: 1))
    }

    private var faceColor: Color {
        guard isEnabled else { return Color(red: 0.20, green: 0.23, blue: 0.30) }
        switch role {
        case .primary: return tint
        case .secondary, .icon: return Color(red: 0.13, green: 0.25, blue: 0.29)
        case .quiet: return Color.white.opacity(0.07)
        }
    }
    private var lipColor: Color {
        guard isEnabled else { return Color(red: 0.11, green: 0.13, blue: 0.18) }
        switch role {
        case .primary: return Color(red: 0.13, green: 0.50, blue: 0.45)
        case .secondary, .icon: return Color(red: 0.05, green: 0.12, blue: 0.15)
        case .quiet: return Color.black.opacity(0.35)
        }
    }
    private var labelColor: Color {
        guard isEnabled else { return Color.white.opacity(0.38) }
        switch role {
        case .primary: return Color(red: 0.03, green: 0.09, blue: 0.13)
        case .secondary, .icon: return tint
        case .quiet: return Color.white.opacity(0.88)
        }
    }
    private var rimColor: Color {
        guard isEnabled else { return Color.white.opacity(0.06) }
        switch role {
        case .primary: return Color.white.opacity(0.35)
        case .secondary, .icon: return tint.opacity(0.35)
        case .quiet: return Color.white.opacity(0.14)
        }
    }
    private var glowColor: Color {
        guard isEnabled, role == .primary else { return .clear }
        return tint.opacity(pressed ? 0.18 : 0.42)
    }
}

// MARK: - Wrapping toolbar

/// Lays buttons out left to right and moves a whole button to the next row when
/// it doesn't fit, instead of squeezing its label.
nonisolated struct StudioFlowLayout: Layout {
    var spacing: CGFloat = 10
    var rowSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.map(\.height).reduce(0, +) + rowSpacing * CGFloat(max(rows.count - 1, 0))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(width: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y + (row.height - size.height) / 2),
                                      proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + rowSpacing
        }
    }

    private struct Row { var indices: [Int] = []; var width: CGFloat = 0; var height: CGFloat = 0 }

    private func arrange(width maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var row = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = row.indices.isEmpty ? size.width : row.width + spacing + size.width
            if !row.indices.isEmpty && needed > maxWidth {
                rows.append(row)
                row = Row()
            }
            row.width = row.indices.isEmpty ? size.width : row.width + spacing + size.width
            row.height = max(row.height, size.height)
            row.indices.append(index)
        }
        if !row.indices.isEmpty { rows.append(row) }
        return rows
    }
}

// MARK: - Live preview document

enum StudioPreviewDocument {
    /// iOS keyboards insert curly quotes and long dashes; code needs plain ones.
    static func straighten(_ source: String) -> String {
        source
            .replacingOccurrences(of: "\u{201C}", with: "\"").replacingOccurrences(of: "\u{201D}", with: "\"")
            .replacingOccurrences(of: "\u{2018}", with: "'").replacingOccurrences(of: "\u{2019}", with: "'")
            .replacingOccurrences(of: "\u{2014}", with: "--")
    }

    /// A self-contained page: the app supplies the arena, the target and the
    /// score; the learner's CSS or JavaScript brings it to life. A content
    /// security policy blocks every network request, so the preview is for
    /// viewing only.
    static func html(track: ProjectTrack, code: String) -> String {
        let source = straighten(code)
        let userCSS = track == .design ? source.replacingOccurrences(of: "</", with: "<\\/") : ""
        let userJS = track == .build ? source.replacingOccurrences(of: "</", with: "<\\/") : ""
        let page = """
        <!doctype html>
        <html><head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; script-src 'unsafe-inline'; img-src data:; font-src data:">
        <script>
        (function(){
          var post = function(type, message){ try { window.webkit.messageHandlers.studio.postMessage({type: type, message: String(message)}); } catch (e) {} };
          var firstUserLine = __USER_CODE_LINE__;
          window.addEventListener('error', function(e){
            var line = e.lineno ? e.lineno - firstUserLine + 1 : 0;
            post('error', (e.message || 'Error') + (line > 0 ? ' — line ' + line + ' of your code' : ''));
          });
          ['log','info','warn','error'].forEach(function(level){
            var original = console[level];
            console[level] = function(){
              var text = Array.prototype.map.call(arguments, function(v){ try { return typeof v === 'string' ? v : JSON.stringify(v); } catch (err) { return String(v); } }).join(' ');
              post(level === 'error' ? 'error' : 'log', text);
              if (original) original.apply(console, arguments);
            };
          });
          post('ready', '');
        })();
        </script>
        <style>
        :where(html, body) { margin: 0; height: 100%; }
        :where(body) { background: #0b1220; font-family: -apple-system, system-ui, sans-serif; -webkit-user-select: none; user-select: none; }
        :where(.arena) { min-height: 100%; box-sizing: border-box; padding: 24px; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 18px; background: #1e293b; color: #94a3b8; transition: background-color .25s, color .25s; }
        :where(.arena h1) { margin: 0; font-size: 22px; letter-spacing: .02em; }
        :where(.target) { width: 128px; height: 128px; border-radius: 32px; display: grid; place-items: center; font-weight: 800; font-size: 18px; background: #475569; color: #0b1220; box-shadow: 0 8px 0 rgba(0,0,0,.35); cursor: pointer; transition: transform .08s, box-shadow .08s, background-color .25s; touch-action: manipulation; }
        :where(.target.is-hit) { transform: translateY(6px) scale(.97); box-shadow: 0 2px 0 rgba(0,0,0,.35); }
        :where(.score) { margin: 0; font: 600 16px ui-monospace, Menlo, monospace; }
        </style>
        <style>\(userCSS)</style>
        </head><body>
        <main class="arena">
          <h1>\(track == .design ? "Arcade Café" : "Tap Dash")</h1>
          <div class="target" role="button" aria-label="Target">TAP</div>
          <p class="score">Score: <span id="score">0</span></p>
        </main>
        <script>
        (function(){
          var target = document.querySelector('.target');
          target.addEventListener('pointerdown', function(){ target.classList.add('is-hit'); });
          ['pointerup','pointercancel','pointerleave'].forEach(function(t){ target.addEventListener(t, function(){ target.classList.remove('is-hit'); }); });
        })();
        </script>
        \(track == .design ? designPlayScript : "<script id=\"user-code\">\n\(userJS)\n</script>")
        <script>
        (function(){
          var label = document.getElementById('score'), last = null;
          function sync(){
            try { if (typeof score !== 'undefined' && score !== last) { last = score; label.textContent = score; } } catch (e) {}
            requestAnimationFrame(sync);
          }
          requestAnimationFrame(sync);
        })();
        </script>
        </body></html>
        """
        // Report error lines relative to the learner's own file, not the page.
        var firstLine = 0
        if let tag = page.range(of: "<script id=\"user-code\">") {
            firstLine = page[..<tag.lowerBound].reduce(1) { $1 == "\n" ? $0 + 1 : $0 } + 1
        }
        return page.replacingOccurrences(of: "__USER_CODE_LINE__", with: String(firstLine))
    }

    /// Design missions style the game; this keeps the target tappable so the
    /// palette can be judged in motion.
    private static let designPlayScript = """
    <script>
    (function(){
      var points = 0, label = document.getElementById('score');
      document.querySelector('.target').addEventListener('click', function(){ points += 1; label.textContent = points; });
    })();
    </script>
    """
}

// MARK: - Live preview web view

struct StudioPreviewWebView: UIViewRepresentable {
    let html: String
    let reloadToken: Int
    var onMessage: (String, String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onMessage: onMessage) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        config.userContentController.add(WeakScriptHandler(context.coordinator), name: "studio")
        config.allowsInlineMediaPlayback = false
        let web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = context.coordinator
        web.isOpaque = false
        web.backgroundColor = UIColor(red: 0.043, green: 0.071, blue: 0.125, alpha: 1)
        web.scrollView.backgroundColor = web.backgroundColor
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.isInspectable = false
        web.accessibilityLabel = "Live preview of your code"
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {
        context.coordinator.onMessage = onMessage
        guard context.coordinator.loadedHTML != html || context.coordinator.loadedToken != reloadToken else { return }
        context.coordinator.loadedHTML = html
        context.coordinator.loadedToken = reloadToken
        web.loadHTMLString(html, baseURL: nil)
    }

    static func dismantleUIView(_ web: WKWebView, coordinator: Coordinator) {
        web.configuration.userContentController.removeScriptMessageHandler(forName: "studio")
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var onMessage: (String, String) -> Void
        var loadedHTML: String?
        var loadedToken = -1
        init(onMessage: @escaping (String, String) -> Void) { self.onMessage = onMessage }

        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: Any], let type = body["type"] as? String else { return }
            let text = body["message"] as? String ?? ""
            DispatchQueue.main.async { self.onMessage(type, text) }
        }

        // Viewing only: the page can't navigate anywhere.
        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            let scheme = action.request.url?.scheme ?? "about"
            decisionHandler(scheme == "about" ? .allow : .cancel)
        }
    }

    /// WKUserContentController retains its handlers strongly.
    private final class WeakScriptHandler: NSObject, WKScriptMessageHandler {
        weak var target: WKScriptMessageHandler?
        init(_ target: WKScriptMessageHandler) { self.target = target }
        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            target?.userContentController(controller, didReceive: message)
        }
    }
}

// MARK: - Preview panel (browser chrome + console)

struct StudioPreviewPanel: View {
    let track: ProjectTrack
    let code: String
    var compactChrome = false
    @State private var html = ""
    @State private var reloadToken = 0
    @State private var consoleLine = ""
    @State private var consoleIsError = false
    @State private var errorCount = 0

    private var fileName: String { track == .design ? "styles.css" : "game.js" }

    var body: some View {
        VStack(spacing: 0) {
            chrome
            ZStack {
                Color(red: 0.043, green: 0.071, blue: 0.125)
                if !html.isEmpty {
                    StudioPreviewWebView(html: html, reloadToken: reloadToken) { type, text in
                        switch type {
                        case "ready": consoleLine = ""; consoleIsError = false; errorCount = 0
                        case "error": consoleLine = text; consoleIsError = true; errorCount += 1
                        default: if !consoleIsError { consoleLine = text }
                        }
                    }
                }
            }
            console
        }
        .background(Color(red: 0.043, green: 0.071, blue: 0.125))
        .clipShape(RoundedRectangle(cornerRadius: compactChrome ? 0 : 20, style: .continuous))
        .overlay {
            if !compactChrome {
                RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white.opacity(0.14))
            }
        }
        // Rebuild the page shortly after typing pauses, so every keystroke doesn't reload it.
        .task(id: "\(track.rawValue)|\(code)") {
            if !html.isEmpty { try? await Task.sleep(for: .milliseconds(450)) }
            guard !Task.isCancelled else { return }
            html = StudioPreviewDocument.html(track: track, code: code)
        }
    }

    private var chrome: some View {
        HStack(spacing: 10) {
            HStack(spacing: 5) {
                Circle().fill(Color(red: 1, green: 0.42, blue: 0.42)).frame(width: 9, height: 9)
                Circle().fill(Color(red: 1, green: 0.78, blue: 0.30)).frame(width: 9, height: 9)
                Circle().fill(Color.mint).frame(width: 9, height: 9)
            }.accessibilityHidden(true)
            HStack(spacing: 6) {
                Image(systemName: "lock.fill").font(.caption2)
                Text("preview://\(track == .design ? "arcade-cafe" : "tap-dash")").lineLimit(1).truncationMode(.middle)
                Spacer(minLength: 4)
                Text("VIEW ONLY").font(.system(size: 9, weight: .heavy)).tracking(0.8)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(Color.mint.opacity(0.16), in: Capsule()).foregroundStyle(.mint)
            }
            .font(.caption.monospaced())
            .foregroundStyle(.white.opacity(0.7))
            .padding(.horizontal, 10).frame(height: 30)
            .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            Button {
                reloadToken += 1
            } label: {
                Image(systemName: "arrow.clockwise").font(.subheadline.weight(.bold))
            }
            .buttonStyle(.studioKey(.quiet, tint: .mint))
            .accessibilityLabel("Reload preview")
        }
        .padding(.horizontal, 12).padding(.top, 10).padding(.bottom, 6)
        .background(Color(red: 0.07, green: 0.11, blue: 0.19))
    }

    private var console: some View {
        HStack(spacing: 8) {
            Image(systemName: consoleIsError ? "exclamationmark.triangle.fill" : "terminal.fill")
                .foregroundStyle(consoleIsError ? Color(red: 1, green: 0.55, blue: 0.5) : .mint)
            Text(consoleLine.isEmpty ? "Running \(fileName) · updates as you type" : consoleLine)
                .lineLimit(2)
                .foregroundStyle(consoleIsError ? Color(red: 1, green: 0.72, blue: 0.68) : Color.white.opacity(0.62))
            Spacer(minLength: 0)
            if errorCount > 1 { Text("\(errorCount)").font(.caption2.bold()).padding(5).background(Color.red.opacity(0.3), in: Circle()) }
        }
        .font(.caption.monospaced())
        .padding(.horizontal, 12).padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.035, green: 0.055, blue: 0.10))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(consoleIsError ? "Error: \(consoleLine)" : "Console")
    }
}

// MARK: - Split divider

struct StudioSplitHandle: View {
    @Binding var fraction: Double
    let totalWidth: CGFloat
    @GestureState private var dragging = false
    @State private var startFraction: Double?

    var body: some View {
        ZStack {
            Rectangle().fill(Color.white.opacity(dragging ? 0.16 : 0.06)).frame(width: 1)
            Capsule().fill(dragging ? Color.mint : Color.white.opacity(0.35)).frame(width: 5, height: 46)
        }
        .frame(width: 22)
        .frame(maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 2)
                .updating($dragging) { _, state, _ in state = true }
                .onChanged { value in
                    let start = startFraction ?? fraction
                    if startFraction == nil { startFraction = fraction }
                    fraction = min(0.72, max(0.32, start + Double(value.translation.width / max(totalWidth, 1))))
                }
                .onEnded { _ in startFraction = nil }
        )
        .sensoryFeedback(.selection, trigger: dragging)
        .accessibilityElement()
        .accessibilityLabel("Resize editor and preview")
        .accessibilityValue("\(Int(fraction * 100)) percent editor")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: fraction = min(0.72, fraction + 0.05)
            case .decrement: fraction = max(0.32, fraction - 0.05)
            @unknown default: break
            }
        }
    }
}

// MARK: - Orientation: portrait everywhere except the Studio tab

/// Asked by iOS every time it decides whether the screen may rotate.
final class StackSprintAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        OrientationLock.mask
    }
}

@MainActor enum OrientationLock {
    static var mask: UIInterfaceOrientationMask = .portrait

    /// Studio allows sideways; everywhere else snaps back to portrait.
    static func set(_ newMask: UIInterfaceOrientationMask) {
        guard newMask != mask else { return }
        mask = newMask
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            windowScene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            if newMask == .portrait {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)) { _ in }
            }
        }
    }
}

extension View {
    /// Lets this screen (and anything it pushes or presents) rotate to landscape.
    func allowsLandscape() -> some View {
        onAppear { OrientationLock.set(.allButUpsideDown) }
            .onDisappear { OrientationLock.set(.portrait) }
    }
}
