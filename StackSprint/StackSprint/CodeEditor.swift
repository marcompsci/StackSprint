import SwiftUI
import UIKit

// MARK: - Code editor
//
// A UITextView tuned for code on a phone:
// - iOS never swaps " for “ or -- for —, and never autocorrects or capitalises.
// - A key bar above the keyboard has the symbols code needs: { } ( ) ; : . = < > /
// - Return keeps the line's indentation and opens a block between braces.
// - Brackets and quotes close themselves; typing the closer steps over it.
// - CSS, JavaScript and HTML are coloured as you type.

enum CodeLanguage: String {
    case css, javascript, html

    var displayName: String {
        switch self {
        case .css: return "CSS"
        case .javascript: return "JavaScript"
        case .html: return "HTML"
        }
    }
}

struct CodeEditor: UIViewRepresentable {
    @Binding var text: String
    var language: CodeLanguage
    var accessibilityLabel: String
    var fontSize: CGFloat = 15

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextView {
        let coordinator = context.coordinator
        let tv = UITextView()
        tv.delegate = coordinator
        tv.backgroundColor = .clear
        tv.textColor = CodeTheme.text
        tv.tintColor = CodeTheme.selector
        tv.font = coordinator.font
        tv.adjustsFontForContentSizeCategory = true
        tv.autocorrectionType = .no
        tv.autocapitalizationType = .none
        tv.spellCheckingType = .no
        tv.smartQuotesType = .no
        tv.smartDashesType = .no
        tv.smartInsertDeleteType = .no
        tv.inlinePredictionType = .no
        tv.keyboardType = .asciiCapable
        tv.keyboardAppearance = .dark
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        tv.alwaysBounceVertical = true
        tv.keyboardDismissMode = .interactive
        tv.accessibilityLabel = accessibilityLabel
        tv.inputAccessoryView = CodeKeyBar(
            onKey: { [weak tv, weak coordinator] key in
                guard let tv, let coordinator else { return }
                coordinator.insert(key, in: tv)
            },
            onDone: { [weak tv] in _ = tv?.resignFirstResponder() }
        )
        tv.text = text
        coordinator.highlight(tv)
        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        let coordinator = context.coordinator
        coordinator.parent = self
        tv.accessibilityLabel = accessibilityLabel
        if tv.text != text {
            // The code changed from outside (a project was loaded, the track switched).
            let previous = tv.selectedRange
            tv.text = text
            let length = (text as NSString).length
            tv.selectedRange = NSRange(location: min(previous.location, length), length: 0)
            coordinator.highlight(tv)
        } else if coordinator.language != language {
            coordinator.highlight(tv)
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: CodeEditor
        var language: CodeLanguage?
        let font: UIFont
        private var applyingEdit = false

        init(_ parent: CodeEditor) {
            self.parent = parent
            font = UIFontMetrics(forTextStyle: .body)
                .scaledFont(for: .monospacedSystemFont(ofSize: parent.fontSize, weight: .regular))
        }

        func highlight(_ tv: UITextView) {
            language = parent.language
            // Never restyle while the keyboard is composing (dictation, marked text).
            guard tv.markedTextRange == nil else { return }
            let selection = tv.selectedRange
            CodeHighlighter.apply(to: tv.textStorage, language: parent.language, font: font)
            tv.typingAttributes = [.font: font, .foregroundColor: CodeTheme.text]
            tv.selectedRange = selection
        }

        func textViewDidChange(_ tv: UITextView) {
            highlight(tv)
            let current = tv.text ?? ""
            if parent.text != current { parent.text = current }
        }

        func textView(_ tv: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if applyingEdit || tv.markedTextRange != nil { return true }
            guard let edit = CodeEditing.edit(for: tv.text ?? "", range: range, replacement: text) else { return true }
            apply(edit, in: tv)
            return false
        }

        /// Input from the key bar goes through the same smarts as typing.
        func insert(_ key: String, in tv: UITextView) {
            let range = tv.selectedRange
            let edit = CodeEditing.edit(for: tv.text ?? "", range: range, replacement: key)
                ?? CodeEditing.Edit(range: range, text: key, cursor: range.location + (key as NSString).length)
            apply(edit, in: tv)
            UIDevice.current.playInputClick()
        }

        private func apply(_ edit: CodeEditing.Edit, in tv: UITextView) {
            applyingEdit = true
            defer { applyingEdit = false }
            if edit.range.length > 0 || !edit.text.isEmpty,
               let start = tv.position(from: tv.beginningOfDocument, offset: edit.range.location),
               let end = tv.position(from: start, offset: edit.range.length),
               let textRange = tv.textRange(from: start, to: end) {
                tv.replace(textRange, withText: edit.text) // goes through the undo manager
            }
            let length = ((tv.text ?? "") as NSString).length
            tv.selectedRange = NSRange(location: min(edit.cursor, length), length: 0)
            textViewDidChange(tv)
        }
    }
}

// MARK: - Editing rules

enum CodeEditing {
    struct Edit {
        let range: NSRange
        let text: String
        let cursor: Int
    }

    static let indentUnit = "  "
    private static let pairs: [String: String] = ["{": "}", "(": ")", "[": "]", "\"": "\"", "'": "'", "`": "`"]
    private static let closers: Set<String> = ["}", ")", "]", "\"", "'", "`"]

    /// Returns the edit to make instead of the plain one, or nil to let the text view insert as usual.
    static func edit(for text: String, range: NSRange, replacement: String) -> Edit? {
        let ns = text as NSString
        guard range.location != NSNotFound, range.location + range.length <= ns.length else { return nil }
        let end = range.location + range.length
        let next: String? = end < ns.length ? ns.substring(with: NSRange(location: end, length: 1)) : nil
        let prev: String? = range.location > 0 ? ns.substring(with: NSRange(location: range.location - 1, length: 1)) : nil
        let utf16 = { (s: String) in (s as NSString).length }

        // Tab (key bar or hardware keyboard) indents with spaces.
        if replacement == "\t" {
            return Edit(range: range, text: indentUnit, cursor: range.location + utf16(indentUnit))
        }

        // Return keeps the current indentation, and opens a block between brackets.
        if replacement == "\n" {
            let lineStart = ns.lineRange(for: NSRange(location: range.location, length: 0)).location
            let before = ns.substring(with: NSRange(location: lineStart, length: range.location - lineStart))
            let indent = String(before.prefix { $0 == " " || $0 == "\t" })
            let opensBlock = prev.map { $0 == "{" || $0 == "(" || $0 == "[" } ?? false
            if opensBlock, let p = prev, let n = next, pairs[p] == n {
                let inner = "\n" + indent + indentUnit
                return Edit(range: range, text: inner + "\n" + indent, cursor: range.location + utf16(inner))
            }
            let inserted = "\n" + indent + (opensBlock ? indentUnit : "")
            return Edit(range: range, text: inserted, cursor: range.location + utf16(inserted))
        }

        // Typing a closer that's already next to the cursor steps over it.
        if range.length == 0, closers.contains(replacement), next == replacement {
            return Edit(range: NSRange(location: range.location, length: 0), text: "", cursor: range.location + 1)
        }

        if let closer = pairs[replacement] {
            // With text selected, brackets and quotes wrap it.
            if range.length > 0 {
                let selected = ns.substring(with: range)
                let wrapped = replacement + selected + closer
                return Edit(range: range, text: wrapped, cursor: range.location + utf16(wrapped))
            }
            // Otherwise close the pair, unless the cursor is up against a word
            // (so apostrophes in "don't" and calls like fn(x stay natural).
            let isWordChar = { (s: String?) -> Bool in
                guard let s else { return false }
                return s.rangeOfCharacter(from: .alphanumerics) != nil || s == "_" || s == "$"
            }
            let isQuote = replacement == closer
            if !isWordChar(next) && !(isQuote && isWordChar(prev)) {
                return Edit(range: range, text: replacement + closer, cursor: range.location + 1)
            }
            return nil
        }

        // Backspace between an empty pair deletes both halves.
        if replacement.isEmpty, range.length == 1 {
            let deleted = ns.substring(with: range)
            if let closer = pairs[deleted], next == closer {
                return Edit(range: NSRange(location: range.location, length: 2), text: "", cursor: range.location)
            }
        }
        return nil
    }
}

// MARK: - Syntax colours

enum CodeTheme {
    static let background = UIColor(red: 0.055, green: 0.09, blue: 0.15, alpha: 1)
    static let text = UIColor(red: 0.82, green: 0.91, blue: 0.94, alpha: 1)
    static let comment = UIColor(red: 0.48, green: 0.55, blue: 0.65, alpha: 1)
    static let string = UIColor(red: 0.99, green: 0.79, blue: 0.50, alpha: 1)
    static let keyword = UIColor(red: 0.79, green: 0.63, blue: 1.00, alpha: 1)
    static let number = UIColor(red: 0.98, green: 0.63, blue: 0.53, alpha: 1)
    static let property = UIColor(red: 0.50, green: 0.84, blue: 0.96, alpha: 1)
    static let selector = UIColor(red: 0.40, green: 0.91, blue: 0.78, alpha: 1)
    static let function = UIColor(red: 0.60, green: 0.77, blue: 1.00, alpha: 1)
}

enum CodeHighlighter {
    private struct Rule {
        let regex: NSRegularExpression
        let color: UIColor
        let group: Int
    }

    private static func rule(_ pattern: String, _ color: UIColor, group: Int = 0) -> Rule? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return nil }
        return Rule(regex: regex, color: color, group: group)
    }

    // Later rules win, so the most specific come last.
    private static let cssRules: [Rule] = [
        rule(#"([A-Za-z-]+)\s*:(?!:)"#, CodeTheme.property, group: 1),
        rule(#"(?<![\w#-])-?\d*\.?\d+(?:px|rem|em|%|vh|vw|ms|s|deg|fr)?"#, CodeTheme.number),
        rule(#"#[0-9a-fA-F]{3,8}\b"#, CodeTheme.number),
        rule(#"^[ \t]*([^{}\n@/][^{}\n]*?)\s*\{"#, CodeTheme.selector, group: 1),
        rule(#"@[A-Za-z-]+|!important"#, CodeTheme.keyword),
    ].compactMap { $0 }

    private static let jsRules: [Rule] = [
        rule(#"\.([A-Za-z_$][\w$]*)"#, CodeTheme.property, group: 1),
        rule(#"\b([A-Za-z_$][\w$]*)\s*(?=\()"#, CodeTheme.function, group: 1),
        rule(#"\b(?:const|let|var|function|return|if|else|for|while|do|switch|case|break|continue|new|class|extends|import|export|from|default|try|catch|finally|throw|typeof|instanceof|in|of|async|await|this|null|undefined|true|false)\b"#, CodeTheme.keyword),
        rule(#"\b\d+(?:\.\d+)?\b"#, CodeTheme.number),
    ].compactMap { $0 }

    private static let htmlRules: [Rule] = [
        rule(#"</?([A-Za-z][\w-]*)"#, CodeTheme.selector, group: 1),
        rule(#"\s([A-Za-z_:@][\w:.-]*)(?=\s*=)"#, CodeTheme.property, group: 1),
    ].compactMap { $0 }

    // Strings and comments are scanned together, left to right, so a "//"
    // inside a string stays a string and a quote inside a comment stays a comment.
    // Group 1 = comment, group 2 = string.
    private static let cssStringsAndComments = try? NSRegularExpression(
        pattern: #"(/\*[\s\S]*?(?:\*/|\z))|("(?:[^"\\\n]|\\.)*"?|'(?:[^'\\\n]|\\.)*'?)"#)
    private static let jsStringsAndComments = try? NSRegularExpression(
        pattern: #"(//[^\n]*|/\*[\s\S]*?(?:\*/|\z))|("(?:[^"\\\n]|\\.)*"?|'(?:[^'\\\n]|\\.)*'?|`(?:[^`\\]|\\.)*`?)"#)
    private static let htmlStringsAndComments = try? NSRegularExpression(
        pattern: #"(<!--[\s\S]*?(?:-->|\z))|("[^"\n]*"?|'[^'\n]*'?)"#)

    static func apply(to storage: NSTextStorage, language: CodeLanguage, font: UIFont) {
        let text = storage.string
        let full = NSRange(location: 0, length: storage.length)
        let rules: [Rule]
        let stringsAndComments: NSRegularExpression?
        switch language {
        case .css: rules = cssRules; stringsAndComments = cssStringsAndComments
        case .javascript: rules = jsRules; stringsAndComments = jsStringsAndComments
        case .html: rules = htmlRules; stringsAndComments = htmlStringsAndComments
        }
        storage.beginEditing()
        storage.setAttributes([.font: font, .foregroundColor: CodeTheme.text], range: full)
        for rule in rules {
            for match in rule.regex.matches(in: text, range: full) {
                let range = match.range(at: rule.group)
                if range.location != NSNotFound, range.length > 0 {
                    storage.addAttribute(.foregroundColor, value: rule.color, range: range)
                }
            }
        }
        if let stringsAndComments {
            for match in stringsAndComments.matches(in: text, range: full) {
                let comment = match.range(at: 1)
                let string = match.range(at: 2)
                if comment.location != NSNotFound {
                    storage.addAttribute(.foregroundColor, value: CodeTheme.comment, range: comment)
                } else if string.location != NSNotFound {
                    storage.addAttribute(.foregroundColor, value: CodeTheme.string, range: string)
                }
            }
        }
        storage.endEditing()
    }
}

// MARK: - Key bar above the keyboard

final class CodeKeyBar: UIInputView, UIInputViewAudioFeedback {
    private struct Key {
        let label: String
        let insert: String
        let spoken: String
    }

    private static let keys: [Key] = [
        Key(label: "⇥", insert: "\t", spoken: "Tab"),
        Key(label: "{", insert: "{", spoken: "Open brace"),
        Key(label: "}", insert: "}", spoken: "Close brace"),
        Key(label: "(", insert: "(", spoken: "Open parenthesis"),
        Key(label: ")", insert: ")", spoken: "Close parenthesis"),
        Key(label: ";", insert: ";", spoken: "Semicolon"),
        Key(label: ":", insert: ":", spoken: "Colon"),
        Key(label: ".", insert: ".", spoken: "Period"),
        Key(label: "=", insert: "=", spoken: "Equals"),
        Key(label: "\"", insert: "\"", spoken: "Double quote"),
        Key(label: "'", insert: "'", spoken: "Single quote"),
        Key(label: "<", insert: "<", spoken: "Less than"),
        Key(label: ">", insert: ">", spoken: "Greater than"),
        Key(label: "/", insert: "/", spoken: "Slash"),
        Key(label: "#", insert: "#", spoken: "Hash"),
        Key(label: "[", insert: "[", spoken: "Open bracket"),
        Key(label: "]", insert: "]", spoken: "Close bracket"),
        Key(label: ",", insert: ",", spoken: "Comma"),
        Key(label: "-", insert: "-", spoken: "Minus"),
        Key(label: "+", insert: "+", spoken: "Plus"),
        Key(label: "!", insert: "!", spoken: "Exclamation mark"),
        Key(label: "&", insert: "&", spoken: "Ampersand"),
        Key(label: "|", insert: "|", spoken: "Vertical bar"),
        Key(label: "$", insert: "$", spoken: "Dollar"),
        Key(label: "`", insert: "`", spoken: "Backtick"),
    ]

    var enableInputClicksWhenVisible: Bool { true }

    init(onKey: @escaping (String) -> Void, onDone: @escaping () -> Void) {
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 50), inputViewStyle: .keyboard)
        autoresizingMask = [.flexibleWidth]

        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.alwaysBounceHorizontal = true
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .fill

        for key in Self.keys {
            var config = UIButton.Configuration.filled()
            config.title = key.label
            config.baseBackgroundColor = UIColor(white: 1, alpha: 0.14)
            config.baseForegroundColor = .white
            config.cornerStyle = .medium
            config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 13, bottom: 4, trailing: 13)
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var attributes = incoming
                attributes.font = UIFont.monospacedSystemFont(ofSize: 18, weight: .medium)
                return attributes
            }
            let insert = key.insert
            let button = UIButton(configuration: config, primaryAction: UIAction { _ in onKey(insert) })
            button.accessibilityLabel = key.spoken
            button.widthAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true
            stack.addArrangedSubview(button)
        }

        var doneConfig = UIButton.Configuration.plain()
        doneConfig.image = UIImage(systemName: "keyboard.chevron.compact.down")
        doneConfig.baseForegroundColor = .white
        let done = UIButton(configuration: doneConfig, primaryAction: UIAction { _ in onDone() })
        done.accessibilityLabel = "Hide keyboard"

        [scroll, stack, done].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        addSubview(scroll)
        scroll.addSubview(stack)
        addSubview(done)
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            scroll.topAnchor.constraint(equalTo: topAnchor),
            scroll.bottomAnchor.constraint(equalTo: bottomAnchor),
            scroll.trailingAnchor.constraint(equalTo: done.leadingAnchor, constant: -2),
            done.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -4),
            done.centerYAnchor.constraint(equalTo: centerYAnchor),
            done.widthAnchor.constraint(equalToConstant: 48),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 7),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -7),
            stack.heightAnchor.constraint(equalTo: scroll.frameLayoutGuide.heightAnchor, constant: -14),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }
}
