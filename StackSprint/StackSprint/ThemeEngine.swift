import Combine
import SwiftUI

// MARK: - Theme Preset

enum ThemePreset: String, CaseIterable, Identifiable {
    case `default` = "default"
    case midnight  = "midnight"
    case ocean     = "ocean"
    case neon      = "neon"
    case forest    = "forest"
    case sakura    = "sakura"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .default:  return "Default"
        case .midnight: return "Midnight"
        case .ocean:    return "Ocean"
        case .neon:     return "Neon"
        case .forest:   return "Forest"
        case .sakura:   return "Sakura"
        }
    }

    var icon: String {
        switch self {
        case .default:  return "🌌"
        case .midnight: return "🌙"
        case .ocean:    return "🌊"
        case .neon:     return "⚡️"
        case .forest:   return "🌲"
        case .sakura:   return "🌸"
        }
    }

    var accent: Color {
        switch self {
        case .default:  return .mint
        case .midnight: return .purple
        case .ocean:    return .cyan
        case .neon:     return Color(red: 0.10, green: 1.00, blue: 0.40)
        case .forest:   return Color(red: 0.20, green: 0.84, blue: 0.40)
        case .sakura:   return Color(red: 1.00, green: 0.45, blue: 0.60)
        }
    }

    // Dark-mode navy (background)
    var navy: Color {
        switch self {
        case .default:  return Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(red: 0.094, green: 0.125, blue: 0.22, alpha: 1)
                : UIColor(red: 0.955, green: 0.968, blue: 0.992, alpha: 1)
        })
        case .midnight: return Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(red: 0.07, green: 0.04, blue: 0.18, alpha: 1)
                : UIColor(red: 0.96, green: 0.94, blue: 0.99, alpha: 1)
        })
        case .ocean: return Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(red: 0.04, green: 0.12, blue: 0.22, alpha: 1)
                : UIColor(red: 0.93, green: 0.97, blue: 1.00, alpha: 1)
        })
        case .neon: return Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(red: 0.03, green: 0.07, blue: 0.03, alpha: 1)
                : UIColor(red: 0.95, green: 0.98, blue: 0.95, alpha: 1)
        })
        case .forest: return Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(red: 0.04, green: 0.11, blue: 0.06, alpha: 1)
                : UIColor(red: 0.93, green: 0.97, blue: 0.94, alpha: 1)
        })
        case .sakura: return Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(red: 0.16, green: 0.04, blue: 0.09, alpha: 1)
                : UIColor(red: 1.00, green: 0.96, blue: 0.97, alpha: 1)
        })
        }
    }

    // Dark-mode card color
    var card: Color {
        switch self {
        case .default:  return Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(red: 0.21, green: 0.26, blue: 0.40, alpha: 1)
                : UIColor.white
        })
        case .midnight: return Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(red: 0.16, green: 0.10, blue: 0.28, alpha: 1)
                : UIColor.white
        })
        case .ocean: return Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(red: 0.08, green: 0.20, blue: 0.32, alpha: 1)
                : UIColor.white
        })
        case .neon: return Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(red: 0.07, green: 0.14, blue: 0.07, alpha: 1)
                : UIColor.white
        })
        case .forest: return Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(red: 0.08, green: 0.18, blue: 0.10, alpha: 1)
                : UIColor.white
        })
        case .sakura: return Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(red: 0.26, green: 0.09, blue: 0.16, alpha: 1)
                : UIColor.white
        })
        }
    }
}

// MARK: - Theme Store

@MainActor final class ThemeStore: ObservableObject {
    static let shared = ThemeStore()

    @Published var preset: ThemePreset {
        didSet { UserDefaults.standard.set(preset.rawValue, forKey: "theme.preset") }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "theme.preset") ?? "default"
        preset = ThemePreset(rawValue: saved) ?? .default
    }
}

// MARK: - Theme Picker View

struct ThemePickerSection: View {
    @ObservedObject var themeStore = ThemeStore.shared

    var body: some View {
        Section {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 12)], spacing: 12) {
                ForEach(ThemePreset.allCases) { preset in
                    ThemeChip(preset: preset, isSelected: themeStore.preset == preset) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            themeStore.preset = preset
                            HapticManager.shared.selection()
                        }
                    }
                }
            }
            .padding(.vertical, 6)
        } header: {
            Label("App Theme", systemImage: "paintpalette.fill")
        }
    }
}

private struct ThemeChip: View {
    let preset: ThemePreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(preset.navy)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle().strokeBorder(
                                isSelected ? preset.accent : Color.clear,
                                lineWidth: 3
                            )
                        )
                    Text(preset.icon).font(.title3)
                }
                Text(preset.displayName)
                    .font(.system(size: 10, weight: isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? preset.accent : .secondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(preset.displayName) theme\(isSelected ? ", selected" : "")")
    }
}
