import Combine
import SwiftUI

// MARK: - App Icon Variant
//
// To add alternate icons in Xcode:
//   1. Add icon image sets to Assets.xcassets named:
//      "AppIcon-Neon", "AppIcon-Midnight", "AppIcon-Minimal", "AppIcon-Season1"
//      Each set needs a 1024×1024 image (and @2x/@3x for iPhone).
//   2. In Info.plist, add the CFBundleIcons → CFBundleAlternateIcons keys below (already added).
//   3. This file handles the runtime switching.

enum AppIconVariant: String, CaseIterable, Identifiable {
    case `default` = "default"
    case neon      = "neon"
    case midnight  = "midnight"
    case minimal   = "minimal"
    case season1   = "season1"

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .default:  return "Default"
        case .neon:     return "Neon ⚡️"
        case .midnight: return "Midnight 🌙"
        case .minimal:  return "Minimal"
        case .season1:  return "Season 1 👑"
        }
    }
    var iconName: String? {
        switch self {
        case .default: return nil
        case .neon:    return "AppIcon-Neon"
        case .midnight: return "AppIcon-Midnight"
        case .minimal: return "AppIcon-Minimal"
        case .season1: return "AppIcon-Season1"
        }
    }
    var previewColor: Color {
        switch self {
        case .default:  return .mint
        case .neon:     return Color(red: 0.10, green: 1.00, blue: 0.40)
        case .midnight: return .purple
        case .minimal:  return .white
        case .season1:  return .yellow
        }
    }
    var previewBackground: Color {
        switch self {
        case .default:  return Color(red: 0.094, green: 0.125, blue: 0.22)
        case .neon:     return Color(red: 0.03, green: 0.07, blue: 0.03)
        case .midnight: return Color(red: 0.07, green: 0.04, blue: 0.18)
        case .minimal:  return Color(red: 0.10, green: 0.10, blue: 0.10)
        case .season1:  return Color(red: 0.12, green: 0.10, blue: 0.02)
        }
    }
    // Free users get Default; Pro unlocks all; Season 1 requires Tier 10 or Pro
    func isUnlocked(isPro: Bool, seasonTier: Int) -> Bool {
        switch self {
        case .default:  return true
        case .neon, .midnight, .minimal: return isPro
        case .season1:  return isPro || seasonTier >= 10
        }
    }
}

// MARK: - App Icon Manager

@MainActor final class AppIconManager: ObservableObject {
    static let shared = AppIconManager()

    @Published private(set) var current: AppIconVariant = .default
    @Published var isChanging = false
    @Published var error: String?

    init() {
        if let name = UIApplication.shared.alternateIconName,
           let found = AppIconVariant.allCases.first(where: { $0.iconName == name }) {
            current = found
        }
    }

    func setIcon(_ variant: AppIconVariant) async {
        guard UIApplication.shared.supportsAlternateIcons else {
            error = "Alternate icons are not supported on this device."; return
        }
        isChanging = true
        error = nil
        do {
            try await UIApplication.shared.setAlternateIconName(variant.iconName)
            current = variant
        } catch {
            self.error = error.localizedDescription
        }
        isChanging = false
    }
}

// MARK: - Icon Picker View

struct AppIconPickerSection: View {
    @EnvironmentObject var premiumStore: PremiumStore
    @EnvironmentObject var seasonStore: SeasonStore
    @ObservedObject var iconManager = AppIconManager.shared
    @State private var showingPaywall = false

    var body: some View {
        Section {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 12)], spacing: 16) {
                ForEach(AppIconVariant.allCases) { variant in
                    let unlocked = variant.isUnlocked(isPro: premiumStore.isPro, seasonTier: seasonStore.tier)
                    IconPreviewCell(
                        variant: variant,
                        isSelected: iconManager.current == variant,
                        isUnlocked: unlocked,
                        isChanging: iconManager.isChanging
                    ) {
                        if unlocked {
                            Task { await iconManager.setIcon(variant) }
                            HapticManager.shared.selection()
                        } else {
                            showingPaywall = true
                        }
                    }
                }
            }
            .padding(.vertical, 8)
            if let err = iconManager.error {
                Text(err).font(.caption).foregroundStyle(.red)
            }
        } header: {
            Label("App Icon", systemImage: "app.badge.fill")
        }
        .sheet(isPresented: $showingPaywall) { ProPaywallView().environmentObject(premiumStore) }
    }
}

private struct IconPreviewCell: View {
    let variant: AppIconVariant
    let isSelected: Bool
    let isUnlocked: Bool
    let isChanging: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(variant.previewBackground)
                        .frame(width: 60, height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(
                                    isSelected ? variant.previewColor : Color.white.opacity(0.08),
                                    lineWidth: isSelected ? 2.5 : 1
                                )
                        )

                    // Icon preview (placeholder — shows initials until real icons are added)
                    Text("SS").font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(variant.previewColor)
                        .opacity(isUnlocked ? 1 : 0.3)

                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14)).foregroundStyle(.white.opacity(0.7))
                            .offset(x: 18, y: -18)
                    }
                    if isSelected && isChanging {
                        ProgressView().tint(.white).scaleEffect(0.8)
                    }
                }
                Text(variant.displayName)
                    .font(.system(size: 9, weight: isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? variant.previewColor : .secondary)
                    .multilineTextAlignment(.center).lineLimit(2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(variant.displayName) icon\(isSelected ? ", selected" : "")\(isUnlocked ? "" : ", locked — requires Pro")")
    }
}

// MARK: - Info.plist Alternate Icons Declaration
//
// Add this to Info.plist manually (or via Xcode's target info editor):
//
// <key>CFBundleIcons</key>
// <dict>
//     <key>CFBundlePrimaryIcon</key>
//     <dict>
//         <key>CFBundleIconFiles</key>
//         <array><string>AppIcon</string></array>
//     </dict>
//     <key>CFBundleAlternateIcons</key>
//     <dict>
//         <key>AppIcon-Neon</key>
//         <dict>
//             <key>CFBundleIconFiles</key>
//             <array><string>AppIcon-Neon</string></array>
//         </dict>
//         <key>AppIcon-Midnight</key>
//         <dict>
//             <key>CFBundleIconFiles</key>
//             <array><string>AppIcon-Midnight</string></array>
//         </dict>
//         <key>AppIcon-Minimal</key>
//         <dict>
//             <key>CFBundleIconFiles</key>
//             <array><string>AppIcon-Minimal</string></array>
//         </dict>
//         <key>AppIcon-Season1</key>
//         <dict>
//             <key>CFBundleIconFiles</key>
//             <array><string>AppIcon-Season1</string></array>
//         </dict>
//     </dict>
// </dict>
