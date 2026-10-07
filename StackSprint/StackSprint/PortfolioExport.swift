import Combine
import SwiftUI
import UIKit
import UniformTypeIdentifiers

// MARK: - Portfolio Data

struct PortfolioData {
    let displayName: String
    let completedLessons: [Lesson]
    let streak: Int
    let xp: Int
    let generatedDate: Date

    var byCategory: [(category: String, lessons: [Lesson])] {
        let grouped = Dictionary(grouping: completedLessons, by: \.category)
        return grouped.map { ($0.key, $0.value) }
            .sorted { $0.category < $1.category }
    }

    var totalLessons: Int { completedLessons.count }
    var totalCategories: Int { Set(completedLessons.map(\.category)).count }
}

// MARK: - Portfolio Generator

enum PortfolioGenerator {
    static func html(from data: PortfolioData) -> String {
        let dateStr = formatted(data.generatedDate)
        let categorySections = data.byCategory.map { cat in
            let rows = cat.lessons.map { lesson in
                "<li><strong>\(esc(lesson.term))</strong> — \(esc(lesson.definition))</li>"
            }.joined(separator: "\n")
            return """
            <section class="category">
              <h2>\(esc(cat.category)) <span class="badge">\(cat.lessons.count)</span></h2>
              <ul>\(rows)</ul>
            </section>
            """
        }.joined(separator: "\n")

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>\(esc(data.displayName)) — StackSprint Portfolio</title>
          <style>
            :root { --accent: #5E5CE6; --bg: #0a0e1a; --card: #111827; --text: #e2e8f0; --muted: #94a3b8; }
            * { box-sizing: border-box; margin: 0; padding: 0; }
            body { background: var(--bg); color: var(--text); font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; padding: 40px 24px; }
            .header { text-align: center; margin-bottom: 48px; }
            .header h1 { font-size: 2.4rem; font-weight: 800; color: #fff; }
            .header p { color: var(--muted); margin-top: 8px; font-size: 1rem; }
            .stats { display: flex; justify-content: center; gap: 40px; margin: 32px 0; flex-wrap: wrap; }
            .stat { text-align: center; }
            .stat .value { font-size: 2rem; font-weight: 700; color: var(--accent); }
            .stat .label { font-size: 0.8rem; text-transform: uppercase; letter-spacing: 0.1em; color: var(--muted); margin-top: 4px; }
            .category { background: var(--card); border-radius: 16px; padding: 24px; margin-bottom: 24px; }
            .category h2 { font-size: 1.2rem; font-weight: 700; margin-bottom: 16px; color: #fff; }
            .badge { background: var(--accent); color: #fff; border-radius: 9999px; padding: 2px 10px; font-size: 0.75rem; vertical-align: middle; margin-left: 8px; }
            ul { list-style: none; display: flex; flex-direction: column; gap: 10px; }
            li { padding: 10px 14px; background: rgba(255,255,255,0.04); border-radius: 10px; font-size: 0.9rem; line-height: 1.5; }
            li strong { color: #c4b5fd; }
            .footer { text-align: center; color: var(--muted); font-size: 0.8rem; margin-top: 48px; }
          </style>
        </head>
        <body>
          <div class="header">
            <h1>\(esc(data.displayName))</h1>
            <p>StackSprint Developer Portfolio · Generated \(dateStr)</p>
          </div>
          <div class="stats">
            <div class="stat"><div class="value">\(data.totalLessons)</div><div class="label">Lessons Completed</div></div>
            <div class="stat"><div class="value">\(data.totalCategories)</div><div class="label">Languages</div></div>
            <div class="stat"><div class="value">\(data.streak)</div><div class="label">Day Streak</div></div>
            <div class="stat"><div class="value">\(data.xp)</div><div class="label">Total XP</div></div>
          </div>
          \(categorySections)
          <div class="footer">Built with StackSprint — stacksprint.app</div>
        </body>
        </html>
        """
    }

    static func pdf(from data: PortfolioData) -> Data? {
        let htmlString = html(from: data)
        let bounds = CGRect(x: 0, y: 0, width: 595, height: 842) // A4
        let renderer = UIGraphicsPDFRenderer(bounds: bounds)
        return renderer.pdfData { ctx in
            ctx.beginPage()
            let attrString = NSAttributedString(string: stripHTML(htmlString), attributes: [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.label
            ])
            attrString.draw(in: bounds.insetBy(dx: 36, dy: 48))
        }
    }

    private static func esc(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
         .replacingOccurrences(of: "\"", with: "&quot;")
    }

    private static func stripHTML(_ html: String) -> String {
        guard let data = html.data(using: .utf8),
              let attributed = try? NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.html,
                          .characterEncoding: String.Encoding.utf8.rawValue],
                documentAttributes: nil
              )
        else { return html }
        return attributed.string
    }

    private static func formatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .long; f.timeStyle = .none
        return f.string(from: date)
    }
}

// MARK: - Share Items

struct PortfolioShareItems {
    let htmlItem: PortfolioHTMLFile
    let pdfItem: PortfolioPDFFile?

    struct PortfolioHTMLFile: Transferable {
        let data: Data
        let filename: String

        static var transferRepresentation: some TransferRepresentation {
            DataRepresentation(exportedContentType: .html) { $0.data }
        }
    }

    struct PortfolioPDFFile: Transferable {
        let data: Data

        static var transferRepresentation: some TransferRepresentation {
            DataRepresentation(exportedContentType: .pdf) { $0.data }
        }
    }
}

// MARK: - Portfolio View

struct PortfolioView: View {
    @EnvironmentObject var store: LearningStore
    @State private var showingHTMLShare = false
    @State private var showingPDFShare = false

    private var portfolioData: PortfolioData {
        let allLessons = store.curriculum?.lessons ?? []
        let completed = allLessons.filter { store.completed.contains($0.id) }
        return PortfolioData(
            displayName: "My Portfolio",
            completedLessons: completed,
            streak: store.currentStreak,
            xp: store.practiceXP,
            generatedDate: .now
        )
    }

    private var htmlData: Data {
        Data(PortfolioGenerator.html(from: portfolioData).utf8)
    }
    private var pdfData: Data? { PortfolioGenerator.pdf(from: portfolioData) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    headerCard
                    categoryBreakdown
                    exportButtons
                }
                .padding(20)
            }
            .navigationTitle("Portfolio")
            .navigationBarTitleDisplayMode(.inline)
            .modifier(SprintTheme())
        }
    }

    private var headerCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.gearshape.fill")
                .font(.system(size: 44)).foregroundStyle(.purple)
            Text("Developer Portfolio").font(.title2.bold())
            Text("Your learning journey, ready to share")
                .font(.subheadline).foregroundStyle(.secondary)
            HStack(spacing: 28) {
                statPill("\(portfolioData.totalLessons)", label: "Lessons")
                statPill("\(portfolioData.totalCategories)", label: "Languages")
                statPill("\(portfolioData.streak)🔥", label: "Streak")
                statPill("\(portfolioData.xp) XP", label: "Total")
            }
        }
        .padding(20)
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 20))
    }

    private func statPill(_ value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.headline.bold()).foregroundStyle(.purple)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }

    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Completed by Language").font(.headline)
            if portfolioData.byCategory.isEmpty {
                Text("Complete some lessons to populate your portfolio.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).padding()
            } else {
                ForEach(portfolioData.byCategory, id: \.category) { entry in
                    HStack {
                        Text(entry.category).font(.subheadline.bold())
                        Spacer()
                        Text("\(entry.lessons.count) lesson\(entry.lessons.count == 1 ? "" : "s")")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var exportButtons: some View {
        VStack(spacing: 12) {
            let htmlFile = PortfolioShareItems.PortfolioHTMLFile(data: htmlData, filename: "StackSprint-Portfolio.html")
            ShareLink(item: htmlFile, preview: SharePreview("StackSprint Portfolio (HTML)")) {
                Label("Export as HTML", systemImage: "safari")
                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent).tint(.blue)
            .disabled(portfolioData.completedLessons.isEmpty)

            if let pdf = pdfData {
                let pdfFile = PortfolioShareItems.PortfolioPDFFile(data: pdf)
                ShareLink(item: pdfFile, preview: SharePreview("StackSprint Portfolio (PDF)")) {
                    Label("Export as PDF", systemImage: "doc.fill")
                        .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent).tint(.purple)
                .disabled(portfolioData.completedLessons.isEmpty)
            }
        }
    }
}
