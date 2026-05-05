//
//  MessageRowView.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import SwiftUI
import UIKit

struct MessageRowView: View {
    let message: ChatMessage
    let searchQuery: String

    private var isUser: Bool {
        message.role == .user
    }

    var body: some View {
        HStack(alignment: .top) {
            if isUser {
                Spacer(minLength: 44)
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 7) {
                MessageContentView(
                    text: message.text,
                    isUser: isUser,
                    searchQuery: searchQuery
                )
                    .foregroundStyle(isUser ? .black : .white.opacity(0.9))
                    .padding(.horizontal, isUser ? 15 : 0)
                    .padding(.vertical, isUser ? 12 : 0)
                    .background {
                        if isUser {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.white.opacity(0.92))
                        }
                    }
                    .textSelection(.enabled)
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = message.text
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    }

                if message.state == .stopped {
                    stateBadge("Stopped", foreground: .white.opacity(0.42), background: .white.opacity(0.055))
                } else if message.state == .failed {
                    stateBadge("Failed", foreground: .red.opacity(0.78), background: .red.opacity(0.1))
                }
            }
            .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)

            if !isUser {
                Spacer(minLength: 44)
            }
        }
    }

    private func stateBadge(_ title: String, foreground: Color, background: Color) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(foreground)
            .padding(.horizontal, 8)
            .frame(height: 24)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(background)
            )
    }
}

private struct MessageContentView: View {
    let text: String
    let isUser: Bool
    let searchQuery: String

    private var blocks: [MessageMarkdownBlock] {
        MessageMarkdownParser.blocks(from: text)
    }

    var body: some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 10) {
            ForEach(blocks) { block in
                switch block.kind {
                case .text(let value):
                    inlineText(value)
                case .listItem(let value, let marker):
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(marker)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(isUser ? .black.opacity(0.62) : .white.opacity(0.48))

                        inlineText(value)
                    }
                    .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
                case .code(let value):
                    Text(highlightedText(
                        value,
                        query: searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
                    ))
                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                        .foregroundStyle(isUser ? .black.opacity(0.82) : .white.opacity(0.82))
                        .lineSpacing(3)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(isUser ? Color.black.opacity(0.06) : Color.white.opacity(0.055))
                                .stroke(isUser ? Color.black.opacity(0.08) : Color.white.opacity(0.09), lineWidth: 1)
                        )
                }
            }
        }
    }

    @ViewBuilder
    private func inlineText(_ value: String) -> some View {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        if query.isEmpty, let markdown = try? AttributedString(markdown: value) {
            Text(markdown)
                .font(.system(size: 16, weight: .regular))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(highlightedText(value, query: query))
                .font(.system(size: 16, weight: .regular))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func highlightedText(_ value: String, query: String) -> AttributedString {
        let attributed = NSMutableAttributedString(string: value)
        guard !query.isEmpty else {
            return AttributedString(attributed)
        }

        let nsValue = value as NSString
        var searchRange = NSRange(location: 0, length: nsValue.length)
        let background = isUser ? UIColor.black.withAlphaComponent(0.1) : UIColor.white.withAlphaComponent(0.18)

        while searchRange.location < nsValue.length {
            let foundRange = nsValue.range(
                of: query,
                options: [.caseInsensitive, .diacriticInsensitive],
                range: searchRange
            )
            guard foundRange.location != NSNotFound else { break }

            attributed.addAttribute(.backgroundColor, value: background, range: foundRange)

            let nextLocation = foundRange.location + max(foundRange.length, 1)
            searchRange = NSRange(location: nextLocation, length: nsValue.length - nextLocation)
        }

        return AttributedString(attributed)
    }
}

private struct MessageMarkdownBlock: Identifiable {
    enum Kind {
        case text(String)
        case listItem(String, marker: String)
        case code(String)
    }

    let id = UUID()
    let kind: Kind
}

private enum MessageMarkdownParser {
    static func blocks(from source: String) -> [MessageMarkdownBlock] {
        var blocks: [MessageMarkdownBlock] = []
        var textBuffer: [String] = []
        var codeBuffer: [String] = []
        var isInsideCodeFence = false

        func flushTextBuffer() {
            let text = textBuffer.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                blocks.append(MessageMarkdownBlock(kind: .text(text)))
            }
            textBuffer.removeAll(keepingCapacity: true)
        }

        func flushCodeBuffer() {
            blocks.append(MessageMarkdownBlock(kind: .code(codeBuffer.joined(separator: "\n"))))
            codeBuffer.removeAll(keepingCapacity: true)
        }

        for rawLine in source.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if line.hasPrefix("```") {
                if isInsideCodeFence {
                    flushCodeBuffer()
                } else {
                    flushTextBuffer()
                }
                isInsideCodeFence.toggle()
                continue
            }

            if isInsideCodeFence {
                codeBuffer.append(rawLine)
                continue
            }

            if let item = listItem(from: line) {
                flushTextBuffer()
                blocks.append(MessageMarkdownBlock(kind: .listItem(item.text, marker: item.marker)))
            } else {
                textBuffer.append(rawLine)
            }
        }

        if isInsideCodeFence {
            flushCodeBuffer()
        } else {
            flushTextBuffer()
        }

        return blocks.isEmpty ? [MessageMarkdownBlock(kind: .text(source))] : blocks
    }

    private static func listItem(from line: String) -> (marker: String, text: String)? {
        if line.hasPrefix("- ") || line.hasPrefix("* ") {
            return ("•", String(line.dropFirst(2)))
        }

        guard let dotIndex = line.firstIndex(of: ".") else { return nil }
        let prefix = line[..<dotIndex]
        guard !prefix.isEmpty, prefix.allSatisfy(\.isNumber) else { return nil }

        let afterDot = line.index(after: dotIndex)
        guard afterDot < line.endIndex, line[afterDot] == " " else { return nil }

        return ("\(prefix).", String(line[line.index(after: afterDot)...]))
    }
}
