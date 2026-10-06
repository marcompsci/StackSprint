import SwiftUI

// MARK: - Platform-Adaptive Layout Helpers

/// Maximum content width: wider on visionOS / iPad, narrower on iPhone.
struct AdaptiveMaxWidth: ViewModifier {
    var compact: CGFloat = 680
    var expanded: CGFloat = 900

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: platformMaxWidth)
    }

    private var platformMaxWidth: CGFloat {
        #if os(visionOS)
        return expanded
        #else
        return compact
        #endif
    }
}

/// Applies a platform-appropriate card background.
/// visionOS: system glass material. iOS: SprintPalette.card.
struct AdaptiveCardBackground: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        #if os(visionOS)
        content
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
        #else
        content
            .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: cornerRadius))
        #endif
    }
}

/// Scales padding for visionOS's larger canvas.
struct AdaptivePadding: ViewModifier {
    var ios: CGFloat = 20
    var visionOS: CGFloat = 32

    func body(content: Content) -> some View {
        #if os(visionOS)
        content.padding(visionOS)
        #else
        content.padding(ios)
        #endif
    }
}

extension View {
    func adaptiveMaxWidth(compact: CGFloat = 680, expanded: CGFloat = 900) -> some View {
        modifier(AdaptiveMaxWidth(compact: compact, expanded: expanded))
    }

    func adaptiveCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(AdaptiveCardBackground(cornerRadius: cornerRadius))
    }

    func adaptivePadding(ios: CGFloat = 20, visionOS vos: CGFloat = 32) -> some View {
        modifier(AdaptivePadding(ios: ios, visionOS: vos))
    }
}

// MARK: - visionOS Ornament-Style Tab Sidebar
// On visionOS, SwiftUI TabView renders as a sidebar by default.
// This modifier ensures the correct tab style is applied per platform.

struct PlatformTabStyle: ViewModifier {
    func body(content: Content) -> some View {
        #if os(visionOS)
        content.tabViewStyle(.sidebarAdaptable)
        #else
        content
        #endif
    }
}

extension View {
    func platformTabStyle() -> some View {
        modifier(PlatformTabStyle())
    }
}

// MARK: - visionOS Scene Configuration
// Wire this into WindowGroup in StackSprintApp if building for visionOS:
//
// var body: some Scene {
//     WindowGroup {
//         RootView()
//             ...
//     }
//     #if os(visionOS)
//     .defaultSize(width: 900, height: 700)
//     #endif
// }

// MARK: - Spatial Card (visionOS 3D depth effect, iOS no-op)

struct SpatialCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        #if os(visionOS)
        content()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
            .hoverEffect(.lift)
        #else
        content()
            .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 24))
        #endif
    }
}

// MARK: - visionOS Code Visualizer Placeholder
// Full RealityKit 3D code visualizer would live in a separate ImmersiveSpace.
// The entry point below can be added to StackSprintApp's Scene when targeting visionOS.

#if os(visionOS)
import RealityKit

struct CodeVisualizerView: View {
    let code: String

    var body: some View {
        RealityView { content in
            // Place tokens as floating text entities in 3D space
            let lines = code.components(separatedBy: "\n").prefix(12)
            for (index, line) in lines.enumerated() {
                let entity = ModelEntity()
                entity.position = SIMD3<Float>(0, -Float(index) * 0.08, -0.5)
                content.add(entity)
            }
        }
        .frame(depth: 0.3)
    }
}
#endif
