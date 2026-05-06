//
//  ComposerTextView.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import SwiftUI
import UIKit

struct ComposerTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    @Binding var measuredHeight: CGFloat

    let isEnabled: Bool
    let onSubmit: () -> Void

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.font = .systemFont(ofSize: 16)
        textView.adjustsFontForContentSizeCategory = true
        textView.textColor = .label
        textView.tintColor = .label
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.isScrollEnabled = true
        textView.returnKeyType = .send
        textView.keyboardType = .default
        textView.enablesReturnKeyAutomatically = true
        textView.autocorrectionType = .no
        textView.spellCheckingType = .no
        textView.smartDashesType = .no
        textView.smartQuotesType = .no
        textView.smartInsertDeleteType = .no
        textView.inputAssistantItem.leadingBarButtonGroups = []
        textView.inputAssistantItem.trailingBarButtonGroups = []
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.accessibilityLabel = "Message"
        textView.accessibilityHint = "Type a message. Press return to send."
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.isSynchronizingFromSwiftUI = true
        defer {
            context.coordinator.isSynchronizingFromSwiftUI = false
        }

        if textView.text != text {
            textView.text = text
        }

        textView.textColor = .label
        textView.tintColor = .label
        textView.isEditable = isEnabled
        textView.isSelectable = isEnabled
        context.coordinator.recalculateHeight(for: textView)

        if isFocused && !textView.isFirstResponder {
            DispatchQueue.main.async {
                textView.becomeFirstResponder()
            }
        } else if !isFocused && textView.isFirstResponder {
            DispatchQueue.main.async {
                textView.resignFirstResponder()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: ComposerTextView
        var isSynchronizingFromSwiftUI = false

        init(parent: ComposerTextView) {
            self.parent = parent
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            setFocused(true)
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            setFocused(false)
        }

        func textViewDidChange(_ textView: UITextView) {
            setText(textView.text)
            recalculateHeight(for: textView)
        }

        func textView(
            _ textView: UITextView,
            shouldChangeTextIn range: NSRange,
            replacementText replacement: String
        ) -> Bool {
            guard replacement == "\n" else { return true }
            setFocused(false)
            textView.resignFirstResponder()
            parent.onSubmit()
            return false
        }

        func recalculateHeight(for textView: UITextView) {
            guard textView.bounds.width > 0 else { return }
            let fittingSize = CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude)
            let fittedHeight = textView.sizeThatFits(fittingSize).height
            let clampedHeight = min(max(fittedHeight, 20), 84)

            guard abs(parent.measuredHeight - clampedHeight) > 0.5 else { return }
            DispatchQueue.main.async {
                guard abs(self.parent.measuredHeight - clampedHeight) > 0.5 else { return }

                self.parent.measuredHeight = clampedHeight
            }
        }

        private func setText(_ text: String) {
            guard !isSynchronizingFromSwiftUI else { return }
            guard parent.text != text else { return }

            DispatchQueue.main.async {
                guard self.parent.text != text else { return }

                self.parent.text = text
            }
        }

        private func setFocused(_ isFocused: Bool) {
            guard !isSynchronizingFromSwiftUI else { return }
            guard parent.isFocused != isFocused else { return }

            DispatchQueue.main.async {
                guard self.parent.isFocused != isFocused else { return }

                self.parent.isFocused = isFocused
            }
        }
    }
}
