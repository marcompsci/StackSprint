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
        case .default:  return "sparkles"
        case .midnight: return "moon.fill"
        case .ocean:    return "water.waves"
        case .neon:     return "bolt.fill"
        case .forest:   return "tree.fill"
        case .sakura:   return "camera.macro"
        }
    }

    /// Bright accents for dark mode; deeper ones in light mode. The bright ones measured
    /// 1.3:1 to 2.4:1 on the light background (neon green was nearly invisible); the
    /// light-mode shades are all 4.8:1 or better.
    var accent: Color {
        let (dark, light): ((Double, Double, Double), (Double, Double, Double)) = {
            switch self {
            case .default:  return ((0.00, 0.78, 0.75), (0.00, 0.478, 0.455))
            case .midnight: return ((0.69, 0.32, 0.87), (0.431, 0.235, 0.745))
            case .ocean:    return ((0.20, 0.68, 0.90), (0.00, 0.431, 0.588))
            case .neon:     return ((0.10, 1.00, 0.40), (0.078, 0.49, 0.216))
            case .forest:   return ((0.20, 0.84, 0.40), (0.118, 0.471, 0.235))
            case .sakura:   return ((1.00, 0.45, 0.60), (0.745, 0.157, 0.353))
            }
        }()
        return Color(uiColor: UIColor { traits in
            let c = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
        })
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
                        withAnimation(.smooth(duration: 0.2)) {
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
                    Circle().fill(preset.accent).frame(width: 14, height: 14)
                }
                Text(preset.displayName)
                    .font(.caption2.weight(isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? preset.accent : .secondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(preset.displayName) theme\(isSelected ? ", selected" : "")")
    }
}
