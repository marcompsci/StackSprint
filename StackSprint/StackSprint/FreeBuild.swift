import Combine
import SwiftUI
import UIKit
import UniformTypeIdentifiers

// MARK: - Free build
//
// Your own small page: index.html, styles.css and script.js, with the live
// preview beside or below. Projects are kept on this device.

@MainActor final class FreeBuildSession: ObservableObject {
    struct Project: Codable, Identifiable, Equatable {
        var id: String
        var name: String
        var html: String
        var css: String
        var js: String
        var updated: Date
    }

    enum File: String, CaseIterable, Identifiable {
        case html, css, js
        var id: String { rawValue }
        var fileName: String {
            switch self {
            case .html: return "index.html"
            case .css: return "styles.css"
            case .js: return "script.js"
            }
        }
        var language: CodeLanguage {
            switch self {
            case .html: return .html
            case .css: return .css
            case .js: return .javascript
            }
        }
    }

    @Published private(set) var projects: [Project] = []
    @Published private(set) var currentID: String = ""
    @Published var file: File = .html

    private let storeKey = "studio.free.projects.v1"
    private let currentKey = "studio.free.current"

    init() {
        load()
        if projects.isEmpty {
            create(from: .counter)
        } else {
            let saved = UserDefaults.standard.string(forKey: currentKey) ?? ""
            currentID = projects.contains { $0.id == saved } ? saved : projects[0].id
        }
    }

    var current: Project {
        projects.first { $0.id == currentID } ?? projects.first
            ?? Project(id: "", name: "", html: "", css: "", js: "", updated: Date())
    }

    var sortedProjects: [Project] { projects.sorted { $0.updated > $1.updated } }

    var document: String {
        StudioPreviewDocument.freeBuild(html: current.html, css: current.css, js: current.js)
    }

    var exportFileName: String {
        let slug = current.name.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }.joined(separator: "-")
        return (slug.isEmpty ? "my-page" : slug) + ".html"
    }

    func text(for file: File) -> String {
        switch file {
        case .html: return current.html
        case .css: return current.css
        case .js: return current.js
        }
    }

    func setText(_ text: String, for file: File) {
        guard let index = projects.firstIndex(where: { $0.id == currentID }) else { return }
        switch file {
        case .html: guard projects[index].html != text else { return }; projects[index].html = text
        case .css: guard projects[index].css != text else { return }; projects[index].css = text
        case .js: guard projects[index].js != text else { return }; projects[index].js = text
        }
        projects[index].updated = Date()
        persist()
    }

    func create(from template: FreeBuildTemplate) {
        let base = template == .blank ? "My page" : template.title
        let taken = Set(projects.map(\.name))
        var name = base
        var n = 2
        while taken.contains(name) { name = "\(base) \(n)"; n += 1 }
        let project = Project(id: UUID().uuidString, name: name, html: template.html,
                              css: template.css, js: template.js, updated: Date())
        projects.append(project)
        select(project.id)
        file = template == .blank ? .html : .js
        persist()
    }

    func select(_ id: String) {
        guard projects.contains(where: { $0.id == id }) else { return }
        currentID = id
        UserDefaults.standard.set(id, forKey: currentKey)
    }

    func renameCurrent(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = projects.firstIndex(where: { $0.id == currentID }) else { return }
        projects[index].name = trimmed
        persist()
    }

    func deleteCurrent() {
        projects.removeAll { $0.id == currentID }
        if let next = sortedProjects.first { select(next.id) } else { create(from: .blank) }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(data, forKey: storeKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storeKey),
              let decoded = try? JSONDecoder().decode([Project].self, from: data) else { return }
        projects = decoded
    }
}

// MARK: - Templates

enum FreeBuildTemplate: String, CaseIterable, Identifiable {
    case counter, todo, colorMixer, tapGame, blank

    var id: String { rawValue }

    var title: String {
        switch self {
        case .counter: return "Counter"
        case .todo: return "To-do list"
        case .colorMixer: return "Colour mixer"
        case .tapGame: return "Tap game"
        case .blank: return "Blank page"
        }
    }

    var symbol: String {
        switch self {
        case .counter: return "plusminus"
        case .todo: return "checklist"
        case .colorMixer: return "slider.horizontal.3"
        case .tapGame: return "hand.tap"
        case .blank: return "doc"
        }
    }

    var summary: String {
        switch self {
        case .counter: return "Two buttons and a number"
        case .todo: return "Add tasks, tap to finish them"
        case .colorMixer: return "Sliders that mix a colour"
        case .tapGame: return "Catch the dot before time runs out"
        case .blank: return "Start from nothing"
        }
    }

    private static let baseCSS = """
    body {
      margin: 0;
      min-height: 100vh;
      display: grid;
      place-items: center;
      background: #0f172a;
      color: #e2e8f0;
      font-family: -apple-system, system-ui, sans-serif;
    }

    """

    var html: String {
        switch self {
        case .counter:
            return """
            <main class="card">
              <h1>Counter</h1>
              <p class="count" id="count">0</p>
              <div class="row">
                <button id="minus" aria-label="Minus one">-</button>
                <button id="plus" aria-label="Plus one">+</button>
              </div>
            </main>
            """
        case .todo:
            return """
            <main class="card">
              <h1>To-do</h1>
              <form id="form">
                <input id="field" placeholder="Add a task" autocomplete="off">
                <button>Add</button>
              </form>
              <ul id="list"></ul>
            </main>
            """
        case .colorMixer:
            return """
            <main class="card">
              <div class="swatch" id="swatch"></div>
              <p class="hex" id="hex">#5eead4</p>
              <label>Red <input type="range" id="r" min="0" max="255" value="94"></label>
              <label>Green <input type="range" id="g" min="0" max="255" value="234"></label>
              <label>Blue <input type="range" id="b" min="0" max="255" value="212"></label>
            </main>
            """
        case .tapGame:
            return """
            <main class="game" id="game">
              <p class="hud"><span id="score">0</span> points · <span id="time">20</span>s</p>
              <button class="dot" id="dot" aria-label="Dot"></button>
            </main>
            """
        case .blank:
            return """
            <h1>Hello</h1>
            <p>Edit index.html, styles.css and script.js.</p>
            """
        }
    }

    var css: String {
        switch self {
        case .counter:
            return Self.baseCSS + """
            .card { text-align: center; }

            .count {
              font-size: 72px;
              font-weight: 700;
              margin: 12px 0 24px;
            }

            .row {
              display: flex;
              gap: 12px;
              justify-content: center;
            }

            button {
              width: 64px;
              height: 64px;
              border: 0;
              border-radius: 16px;
              font-size: 28px;
              background: #5eead4;
              color: #0f172a;
            }

            button:active { transform: scale(0.96); }
            """
        case .todo:
            return Self.baseCSS + """
            .card { width: min(320px, 90vw); }

            form { display: flex; gap: 8px; }

            input {
              flex: 1;
              padding: 12px;
              border: 1px solid #334155;
              border-radius: 12px;
              background: #1e293b;
              color: inherit;
              font: inherit;
            }

            button {
              padding: 0 16px;
              border: 0;
              border-radius: 12px;
              background: #5eead4;
              color: #0f172a;
              font: inherit;
              font-weight: 600;
            }

            ul { list-style: none; padding: 0; }

            li {
              padding: 12px;
              border-bottom: 1px solid #1e293b;
            }

            li.done {
              color: #64748b;
              text-decoration: line-through;
            }
            """
        case .colorMixer:
            return Self.baseCSS + """
            .card {
              display: grid;
              gap: 12px;
              width: min(300px, 88vw);
            }

            .swatch {
              height: 140px;
              border-radius: 20px;
              background: #5eead4;
            }

            .hex {
              margin: 0;
              text-align: center;
              font: 600 20px ui-monospace, Menlo, monospace;
            }

            label {
              display: grid;
              gap: 4px;
              font-size: 14px;
              color: #94a3b8;
            }
            """
        case .tapGame:
            return Self.baseCSS + """
            .game {
              position: relative;
              width: 100vw;
              height: 100vh;
            }

            .hud {
              margin: 0;
              padding: 16px;
              text-align: center;
              font-weight: 600;
            }

            .dot {
              position: absolute;
              width: 56px;
              height: 56px;
              border: 0;
              border-radius: 50%;
              background: #f472b6;
              left: 40%;
              top: 40%;
            }
            """
        case .blank:
            return Self.baseCSS + """
            h1 { margin: 0; }
            """
        }
    }

    var js: String {
        switch self {
        case .counter:
            return """
            let count = 0;
            const label = document.getElementById('count');

            function show() {
              label.textContent = count;
            }

            document.getElementById('plus').addEventListener('click', () => {
              count += 1;
              show();
            });

            document.getElementById('minus').addEventListener('click', () => {
              count -= 1;
              show();
            });

            """
        case .todo:
            return """
            const form = document.getElementById('form');
            const field = document.getElementById('field');
            const list = document.getElementById('list');

            form.addEventListener('submit', (event) => {
              event.preventDefault();
              const text = field.value.trim();
              if (!text) return;

              const item = document.createElement('li');
              item.textContent = text;
              item.addEventListener('click', () => item.classList.toggle('done'));
              list.append(item);
              field.value = '';
            });

            """
        case .colorMixer:
            return """
            const sliders = ['r', 'g', 'b'].map((id) => document.getElementById(id));
            const swatch = document.getElementById('swatch');
            const hex = document.getElementById('hex');

            function toHex(value) {
              return Number(value).toString(16).padStart(2, '0');
            }

            function mix() {
              const color = '#' + sliders.map((s) => toHex(s.value)).join('');
              swatch.style.background = color;
              hex.textContent = color;
            }

            sliders.forEach((slider) => slider.addEventListener('input', mix));
            mix();

            """
        case .tapGame:
            return """
            const game = document.getElementById('game');
            const dot = document.getElementById('dot');
            const scoreLabel = document.getElementById('score');
            const timeLabel = document.getElementById('time');

            let score = 0;
            let timeLeft = 20;

            function moveDot() {
              const maxX = game.clientWidth - dot.offsetWidth;
              const maxY = game.clientHeight - dot.offsetHeight;
              dot.style.left = Math.random() * maxX + 'px';
              dot.style.top = Math.random() * maxY + 'px';
            }

            dot.addEventListener('click', () => {
              if (timeLeft === 0) return;
              score += 1;
              scoreLabel.textContent = score;
              moveDot();
            });

            const timer = setInterval(() => {
              timeLeft -= 1;
              timeLabel.textContent = timeLeft;
              if (timeLeft === 0) clearInterval(timer);
            }, 1000);

            """
        case .blank:
            return """
            // Your JavaScript runs after the page loads.

            """
        }
    }
}

// MARK: - Export

/// The page as a standalone .html file for the share sheet (Files, AirDrop, Messages).
nonisolated struct HTMLPageExport: Transferable {
    let fileName: String
    let html: String

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .html) { page in
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(page.fileName)
            try Data(page.html.utf8).write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
    }
}

// MARK: - Views

struct FreeBuildHeader: View {
    @ObservedObject var session: FreeBuildSession
    @State private var renaming = false
    @State private var draftName = ""
    @State private var confirmingDelete = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Free build").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
                Text(session.current.name).font(.title2.bold()).lineLimit(1)
            }
            Spacer(minLength: 8)
            Menu {
                Section("New from a template") {
                    ForEach(FreeBuildTemplate.allCases) { template in
                        Button { session.create(from: template) } label: {
                            Label(template.title, systemImage: template.symbol)
                        }
                    }
                }
                if session.projects.count > 1 {
                    Section("Open") {
                        ForEach(session.sortedProjects) { project in
                            Button { session.select(project.id) } label: {
                                if project.id == session.currentID {
                                    Label(project.name, systemImage: "checkmark")
                                } else {
                                    Text(project.name)
                                }
                            }
                        }
                    }
                }
                Section {
                    Button { draftName = session.current.name; renaming = true } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    Button(role: .destructive) { confirmingDelete = true } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            } label: {
                Label("Projects", systemImage: "folder")
                    .labelStyle(.iconOnly)
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Projects and templates")
        }
        .alert("Rename project", isPresented: $renaming) {
            TextField("Name", text: $draftName)
            Button("Save") { session.renameCurrent(draftName) }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Delete “\(session.current.name)”? This can’t be undone.",
                            isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { session.deleteCurrent() }
        }
    }
}

struct FreeBuildFilePicker: View {
    @ObservedObject var session: FreeBuildSession

    var body: some View {
        Picker("File", selection: $session.file) {
            ForEach(FreeBuildSession.File.allCases) { file in
                Text(file.fileName).tag(file)
            }
        }
        .pickerStyle(.segmented)
    }
}

struct FreeBuildEditor: View {
    @ObservedObject var session: FreeBuildSession
    var fontSize: CGFloat = 15

    var body: some View {
        let file = session.file
        CodeEditor(text: Binding(get: { session.text(for: file) },
                                 set: { session.setText($0, for: file) }),
                   language: file.language,
                   accessibilityLabel: "\(file.fileName) editor",
                   fontSize: fontSize)
            .background(Color(red: 0.055, green: 0.09, blue: 0.15))
    }
}

struct FreeBuildTemplateStrip: View {
    @ObservedObject var session: FreeBuildSession

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Start something new").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(FreeBuildTemplate.allCases) { template in
                        Button { session.create(from: template) } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Image(systemName: template.symbol).font(.title3).foregroundStyle(.mint)
                                Text(template.title).font(.subheadline.weight(.semibold))
                                Text(template.summary).font(.caption).foregroundStyle(.secondary)
                                    .lineLimit(2).multilineTextAlignment(.leading)
                            }
                            .frame(width: 140, height: 104, alignment: .topLeading)
                            .padding(12)
                            .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("New \(template.title): \(template.summary)")
                    }
                }
            }
        }
    }
}

/// Portrait layout: header, file tabs, editor, actions, live preview, templates.
struct FreeBuildPortrait: View {
    @ObservedObject var session: FreeBuildSession
    var onFullScreen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            FreeBuildHeader(session: session)
            FreeBuildFilePicker(session: session)
            FreeBuildEditor(session: session)
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white.opacity(0.12)))
            StudioFlowLayout {
                ShareLink(item: HTMLPageExport(fileName: session.exportFileName, html: session.document),
                          preview: SharePreview(session.exportFileName)) {
                    Label("Export .html", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.studioSecondary)
                Button(action: onFullScreen) {
                    Label("Full screen", systemImage: "arrow.up.left.and.arrow.down.right")
                }
                .buttonStyle(.studioSecondary)
            }
            StudioPreviewPanel(track: .build, code: "", title: session.current.name, customHTML: session.document)
                .frame(height: 380)
            Label("Turn your phone sideways to code and watch the page side by side.", systemImage: "rectangle.split.2x1")
                .font(.subheadline).foregroundStyle(.secondary)
            FreeBuildTemplateStrip(session: session)
        }
    }
}

/// Landscape layout: files and editor on the left, the page on the right.
struct FreeBuildSplit: View {
    @ObservedObject var session: FreeBuildSession
    let totalWidth: CGFloat
    @Binding var fraction: Double

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Text(session.current.name).font(.subheadline.weight(.semibold)).lineLimit(1)
                    Spacer(minLength: 6)
                    FreeBuildFilePicker(session: session).frame(maxWidth: 260)
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(Color(red: 0.10, green: 0.15, blue: 0.25))
                FreeBuildEditor(session: session, fontSize: 14)
                HStack(spacing: 10) {
                    ShareLink(item: HTMLPageExport(fileName: session.exportFileName, html: session.document),
                              preview: SharePreview(session.exportFileName)) {
                        Label("Export .html", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.studioSecondary)
                    Spacer()
                }
                .padding(.horizontal, 12).padding(.top, 8).padding(.bottom, 4)
                .background(Color(red: 0.055, green: 0.09, blue: 0.15))
            }
            .frame(width: max(240, (totalWidth - 22) * fraction))
            StudioSplitHandle(fraction: $fraction, totalWidth: totalWidth)
            StudioPreviewPanel(track: .build, code: "", title: session.current.name,
                               customHTML: session.document, compactChrome: true)
        }
        .background(Color(red: 0.035, green: 0.055, blue: 0.10).ignoresSafeArea())
    }
}
