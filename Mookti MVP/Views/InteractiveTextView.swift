//
//  InteractiveTextView.swift
//  Mookti MVP
//
//  Created on 2025-07-21.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Information about an annotation
struct AnnotationInfo {
    let trigger: String
    let text: String
}

/// A text view that supports tap-to-reveal annotations (formerly "on hover")
struct InteractiveTextView: View {
    let content: String
    @State private var selectedAnnotation: AnnotationInfo?
    @State private var showingPopover = false
    
    /// Parse content to extract text segments and annotations
    private var parsedSegments: [TextSegment] {
        parseInteractiveContent(content)
    }
    
    var body: some View {
        // Build the interactive text
        buildInteractiveText()
            .fixedSize(horizontal: false, vertical: true)
            .popover(isPresented: $showingPopover) {
                if let annotation = selectedAnnotation {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(annotation.text)
                            .font(.callout)
                            .foregroundColor(.primary)
                            .padding()
                            .frame(minWidth: 200, maxWidth: 300)
                    }
                    .background(Color(UIColor.systemBackground))
                    .presentationCompactAdaptation(.popover)
                }
            }
    }
    
    private var tappableComponents: [TappableTextComponent] {
        var components: [TappableTextComponent] = []
        
        for segment in parsedSegments {
            switch segment {
            case .plain(let text):
                components.append(.plain(text))
                
            case .annotated(let trigger, let annotation):
                components.append(.interactive(trigger: trigger, annotation: annotation))
            }
        }
        
        return components
    }
    
    @ViewBuilder
    private func buildInteractiveText() -> some View {
        TappableText(components: tappableComponents) { trigger, annotation in
            selectedAnnotation = AnnotationInfo(trigger: trigger, text: annotation)
            showingPopover = true
        }
    }
    
}

/// Represents a segment of text that may have an annotation
enum TextSegment {
    case plain(String)
    case annotated(trigger: String, annotation: String)
}

/// Component types for tappable text
enum TappableTextComponent {
    case plain(String)
    case interactive(trigger: String, annotation: String)
}

/// Custom `UITextView` that dynamically wraps text without truncation
///
/// The previous implementation relied on accessing the view's
/// `layoutManager` to calculate the height. In iOS 17 this forces
/// the text view into TextKit 1 compatibility mode which can cause
/// long messages to render only partially. By using `sizeThatFits`
/// and updating the `textContainer` width during layout we allow the
/// system to use TextKit 2 and properly compute the intrinsic height
/// for large content blocks.
class WrappingTextView: UITextView {
    override func layoutSubviews() {
        super.layoutSubviews()
        // Ensure the text container matches the current view width so
        // that `sizeThatFits` calculates the correct wrapped height.
        let width = bounds.width
        if textContainer.size.width != width {
            textContainer.size = CGSize(width: width,
                                        height: .greatestFiniteMagnitude)
            // Changing the container width can affect wrapping, so
            // invalidate the intrinsic content size to trigger a
            // recomputation of the view's height.
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        // Ask the system for the size that fits the current width without
        // constraining the height. This respects dynamic type and avoids
        // TextKit compatibility warnings.
        let fittingSize = CGSize(width: bounds.width,
                                 height: .greatestFiniteMagnitude)
        let size = sizeThatFits(fittingSize)
        return CGSize(width: UIView.noIntrinsicMetric, height: size.height)
    }
}

/// A view that renders text with tappable segments using a wrapping layout
struct TappableText: UIViewRepresentable {
    let components: [TappableTextComponent]
    let onTap: (String, String) -> Void
    
    func makeUIView(context: Context) -> UITextView {
        let textView = WrappingTextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.widthTracksTextView = true
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        
        // Build attributed string
        let attributedString = NSMutableAttributedString()
        
        for component in components {
            switch component {
            case .plain(let text):
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.preferredFont(forTextStyle: .body),
                    .foregroundColor: UIColor.label
                ]
                attributedString.append(NSAttributedString(string: text, attributes: attributes))
                
            case .interactive(let trigger, let annotation):
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.preferredFont(forTextStyle: .body),
                    .foregroundColor: UIColor.systemBlue,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .link: "mookti://annotation?trigger=\(trigger.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&text=\(annotation.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
                ]
                attributedString.append(NSAttributedString(string: trigger, attributes: attributes))
            }
        }
        
        textView.attributedText = attributedString
        textView.delegate = context.coordinator
        textView.linkTextAttributes = [
            .foregroundColor: UIColor.systemBlue,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        // Force layout update to ensure proper text wrapping
        textView.invalidateIntrinsicContentSize()
        textView.setNeedsLayout()
        textView.layoutIfNeeded()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        let onTap: (String, String) -> Void
        
        init(onTap: @escaping (String, String) -> Void) {
            self.onTap = onTap
        }
        
        // Use the iOS 17+ method without the deprecated interaction parameter
        func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {
            guard case .link(let url) = textItem.content,
                  url.scheme == "mookti",
                  url.host == "annotation",
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let trigger = components.queryItems?.first(where: { $0.name == "trigger" })?.value?.removingPercentEncoding,
                  let text = components.queryItems?.first(where: { $0.name == "text" })?.value?.removingPercentEncoding else {
                return defaultAction
            }
            
            return UIAction { _ in
                self.onTap(trigger, text)
            }
        }
    }
}

/// Parse content to extract plain text and annotated segments
private func parseInteractiveContent(_ content: String) -> [TextSegment] {
    var segments: [TextSegment] = []
    
    // Combined pattern to match both ${ON HOVER: '...'} and [ON HOVER: ...]
    let pattern = #"(\$\{ON HOVER: '([^']+)'\}|\[ON HOVER: ([^\]]+)\])"#
    
    guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
        return [.plain(content)]
    }
    
    // Find all matches
    let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))
    
    var lastEndIndex = content.startIndex
    
    for match in matches {
        guard let matchRange = Range(match.range, in: content) else { continue }
        
        // Get the annotation text from either capture group 2 or 3
        let annotation: String
        if let range2 = Range(match.range(at: 2), in: content) {
            annotation = String(content[range2])
        } else if let range3 = Range(match.range(at: 3), in: content) {
            annotation = String(content[range3])
        } else {
            continue
        }
        
        // Get text before this match
        let textBeforeMatch = String(content[lastEndIndex..<matchRange.lowerBound])
        
        // Find trigger text (text after last period)
        if let lastPeriodIndex = textBeforeMatch.lastIndex(of: ".") {
            // Split at the period, including the space after it
            let periodIndex = textBeforeMatch.index(after: lastPeriodIndex)
            let beforeTrigger = String(textBeforeMatch[..<periodIndex])
            let triggerText = String(textBeforeMatch[periodIndex...]).trimmingCharacters(in: .whitespaces)
            
            // Ensure there's a space after the period if the trigger exists
            if !triggerText.isEmpty && !beforeTrigger.isEmpty && !beforeTrigger.hasSuffix(" ") {
                segments.append(.plain(beforeTrigger + " "))
            } else {
                segments.append(.plain(beforeTrigger))
            }
            
            if !triggerText.isEmpty {
                // Add annotated trigger
                segments.append(.annotated(trigger: triggerText, annotation: annotation))
                lastEndIndex = matchRange.upperBound
            } else {
                // No valid trigger found, add as plain text
                segments.append(.plain(String(content[matchRange])))
                lastEndIndex = matchRange.upperBound
            }
        } else {
            // No period found, use entire text before match as trigger
            let trigger = textBeforeMatch.trimmingCharacters(in: .whitespaces)
            if !trigger.isEmpty {
                segments.append(.annotated(trigger: trigger, annotation: annotation))
                lastEndIndex = matchRange.upperBound
            } else {
                // Add the whole thing as plain text
                segments.append(.plain(String(content[lastEndIndex..<matchRange.upperBound])))
                lastEndIndex = matchRange.upperBound
            }
        }
    }
    
    // Add any remaining text
    if lastEndIndex < content.endIndex {
        segments.append(.plain(String(content[lastEndIndex...])))
    }
    
    // If no segments were created, return the original content
    if segments.isEmpty {
        return [.plain(content)]
    }
    
    return segments
}

#Preview {
    VStack(alignment: .leading, spacing: 20) {
        InteractiveTextView(content: "It's a major international incident ${ON HOVER: 'And a real one! Though it was soon overshadowed by the events of September 11, 2001 half a year later.'}, with stakes defined in human lives.")
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        
        InteractiveTextView(content: "The motivations are shaped by their position [ON HOVER: Remember that our scenario plays out in early 2001.], and by cultural values.")
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
    }
    .padding()
}