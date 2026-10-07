import SwiftUI

// MARK: - Reduce Motion

/// Wraps an animation in a reduce-motion-safe way.
/// When Reduce Motion is enabled, applies an instant opacity transition instead.
func sprintAnimation<V: Equatable>(
    _ animation: Animation = .easeOut(duration: 0.25),
    value: V,
    reduceMotion: Bool
) -> Animation? {
    reduceMotion ? .none : animation
}

struct ReduceMotionAnimation: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? .none : animation, value: reduceMotion)
    }
}

extension View {
    /// Replace any spring/easeOut animation with `.none` when Reduce Motion is on.
    func reduceMotionAnimation(_ animation: Animation = .easeOut(duration: 0.25)) -> some View {
        modifier(ReduceMotionAnimation(animation: animation))
    }
}

// MARK: - Dynamic Type Helpers

/// Clamps font scaling so oversized Dynamic Type doesn't break layouts.
struct DynamicTypeClamped: ViewModifier {
    var max: DynamicTypeSize = .accessibility2

    func body(content: Content) -> some View {
        content.dynamicTypeSize(.xSmall...max)
    }
}

extension View {
    func clampedDynamicType(max: DynamicTypeSize = .accessibility2) -> some View {
        modifier(DynamicTypeClamped(max: max))
    }
}

// MARK: - Accessibility Button Modifier

extension View {
    /// Convenience modifier that sets both accessibilityLabel and accessibilityHint together.
    func accessibilityButton(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .modifier(OptionalHintModifier(hint: hint))
            .accessibilityAddTraits(.isButton)
    }
}

private struct OptionalHintModifier: ViewModifier {
    let hint: String?
    func body(content: Content) -> some View {
        if let hint {
            content.accessibilityHint(hint)
        } else {
            content
        }
    }
}

// MARK: - Tab Identifiers
// Applied in RootView's TabView to enable UI tests to find each tab by identifier.

extension View {
    func learnTabAccessibility()   -> some View { self.accessibilityIdentifier("tab-learn") }
    func studioTabAccessibility()  -> some View { self.accessibilityIdentifier("tab-studio") }
    func togetherTabAccessibility()-> some View { self.accessibilityIdentifier("tab-together") }
    func statsTabAccessibility()   -> some View { self.accessibilityIdentifier("tab-stats") }
    func accountTabAccessibility() -> some View { self.accessibilityIdentifier("tab-account") }
}

// MARK: - Screen Reader Focus Helper

struct AccessibleCard<Content: View>: View {
    let label: String
    let hint: String?
    let content: () -> Content

    init(label: String, hint: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.label = label; self.hint = hint; self.content = content
    }

    var body: some View {
        content()
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .modifier(OptionalHintModifier(hint: hint))
    }
}

// MARK: - Minimum Touch Target

/// Ensures any tappable control meets Apple's 44×44 pt minimum touch target.
struct MinimumTouchTarget: ViewModifier {
    func body(content: Content) -> some View {
        content.frame(minWidth: 44, minHeight: 44)
    }
}

extension View {
    func minimumTouchTarget() -> some View { modifier(MinimumTouchTarget()) }
}
