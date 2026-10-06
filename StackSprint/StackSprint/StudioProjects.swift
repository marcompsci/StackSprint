import Combine
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Saved Project Model

struct SavedProject: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var track: String        // "design" or "build"
    var code: String
    var lastSaved: Date
    var snapshots: [CodeSnapshot]

    struct CodeSnapshot: Codable, Identifiable, Equatable {
        var id: String
        var code: String
        var savedAt: Date
        var label: String
    }
}

// MARK: - Project Store

@MainActor final class ProjectStore: ObservableObject {
    @Published private(set) var projects: [SavedProject] = []

    private let key = "studio.projects.v2"
    private let maxSnapshotsPerProject = 5

    init() { load() }

    // MARK: – CRUD

    func upsert(id: String, name: String, track: String, code: String) {
        if let idx = projects.firstIndex(where: { $0.id == id }) {
            var p = projects[idx]
            // Save a snapshot before updating
            let snap = SavedProject.CodeSnapshot(
                id: UUID().uuidString,
                code: p.code,
                savedAt: Date(),
                label: "Snapshot \(p.snapshots.count + 1)"
            )
            p.snapshots = Array((p.snapshots + [snap]).suffix(maxSnapshotsPerProject))
            p.code = code
            p.name = name
            p.lastSaved = Date()
            projects[idx] = p
        } else {
            let p = SavedProject(id: id, name: name, track: track,
                                 code: code, lastSaved: Date(), snapshots: [])
            projects.append(p)
        }
        persist()
    }

    func delete(_ id: String) {
        projects.removeAll { $0.id == id }
        persist()
    }

    func restoreSnapshot(_ snapshot: SavedProject.CodeSnapshot, projectID: String) {
        guard let idx = projects.firstIndex(where: { $0.id == projectID }) else { return }
        projects[idx].code = snapshot.code
        projects[idx].lastSaved = Date()
        persist()
    }

    func rename(_ id: String, to name: String) {
        guard let idx = projects.firstIndex(where: { $0.id == id }) else { return }
        projects[idx].name = name
        persist()
    }

    func projectsForTrack(_ track: String) -> [SavedProject] {
        projects.filter { $0.track == track }.sorted { $0.lastSaved > $1.lastSaved }
    }

    // MARK: – Persistence

    private func persist() {
        if let data = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([SavedProject].self, from: data)
        else { return }
        projects = decoded
    }
}

// MARK: - Project Picker Sheet

struct ProjectPickerSheet: View {
    @EnvironmentObject var projectStore: ProjectStore
    let track: String
    let currentCode: String
    var onSelect: (SavedProject) -> Void
    var onNew: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var newName = ""
    @State private var showingNew = false
    @State private var deleteTarget: SavedProject?

    private var trackProjects: [SavedProject] { projectStore.projectsForTrack(track) }
    private let trackLabel: String

    init(track: String, currentCode: String, onSelect: @escaping (SavedProject) -> Void, onNew: @escaping (String) -> Void) {
        self.track = track
        self.currentCode = currentCode
        self.onSelect = onSelect
        self.onNew = onNew
        self.trackLabel = track == "design" ? "CSS Design" : "JavaScript Build"
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Saved \(trackLabel) projects") {
                    if trackProjects.isEmpty {
                        Text("No saved projects yet. Save your current code to start.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    } else {
                        ForEach(trackProjects) { project in
                            ProjectRow(project: project) {
                                onSelect(project)
                                dismiss()
                            }
                            .swipeActions(edge: .trailing) {
                                Button("Delete", role: .destructive) {
                                    projectStore.delete(project.id)
                                }
                            }
                        }
                    }
                }

                Section {
                    Button {
                        showingNew = true
                    } label: {
                        Label("Save current code as new project", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("My Projects")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Project name", isPresented: $showingNew) {
                TextField("My project", text: $newName)
                Button("Save") {
                    let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                    onNew(name.isEmpty ? "Untitled" : name)
                    newName = ""
                    dismiss()
                }
                Button("Cancel", role: .cancel) { newName = "" }
            } message: {
                Text("Give this project a name.")
            }
        }
    }
}

private struct ProjectRow: View {
    @EnvironmentObject var projectStore: ProjectStore
    let project: SavedProject
    let onSelect: () -> Void
    @State private var showSnapshots = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(action: onSelect) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(project.name).font(.headline)
                        Text(timeAgo(project.lastSaved))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if !project.snapshots.isEmpty {
                Button {
                    withAnimation(.easeOut(duration: 0.15)) { showSnapshots.toggle() }
                } label: {
                    Label("\(project.snapshots.count) snapshot\(project.snapshots.count == 1 ? "" : "s")",
                          systemImage: showSnapshots ? "chevron.up" : "clock.arrow.circlepath")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                if showSnapshots {
                    ForEach(project.snapshots.reversed()) { snap in
                        Button {
                            projectStore.restoreSnapshot(snap, projectID: project.id)
                            onSelect()
                        } label: {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.caption2).foregroundStyle(.secondary)
                                Text(snap.label).font(.caption)
                                Text("·").foregroundStyle(.secondary)
                                Text(timeAgo(snap.savedAt)).font(.caption).foregroundStyle(.secondary)
                                Spacer()
                                Text("Restore").font(.caption.bold()).foregroundStyle(.mint)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 14)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        switch interval {
        case ..<60: return "just now"
        case ..<3600: return "\(Int(interval / 60))m ago"
        case ..<86400: return "\(Int(interval / 3600))h ago"
        default: return "\(Int(interval / 86400))d ago"
        }
    }
}

// MARK: - Export Code Transfer

struct CodeFile: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    var code: String

    init(code: String) { self.code = code }
    init(configuration: ReadConfiguration) throws {
        code = (configuration.file.regularFileContents.flatMap { String(data: $0, encoding: .utf8) }) ?? ""
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(code.utf8))
    }
}
