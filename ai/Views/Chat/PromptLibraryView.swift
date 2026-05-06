//
//  PromptLibraryView.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import SwiftUI

struct PromptLibraryView: View {
    let templates: [PromptTemplate]
    let close: () -> Void
    let select: (PromptTemplate) -> Void
    let save: (String, String) -> Void
    let delete: (PromptTemplate) -> Void

    @State private var searchText = ""
    @State private var isAddingTemplate = false
    @State private var draftTitle = ""
    @State private var draftText = ""

    private var filteredTemplates: [PromptTemplate] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return templates }

        return templates.filter { template in
            template.title.localizedCaseInsensitiveContains(query)
            || template.text.localizedCaseInsensitiveContains(query)
            || template.category.localizedCaseInsensitiveContains(query)
        }
    }

    private var canSaveDraft: Bool {
        !draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        searchField

                        if isAddingTemplate {
                            addTemplatePanel
                        }

                        templateList
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
                .scrollIndicators(.hidden)
            }
        }
        .foregroundStyle(AppTheme.foreground)
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Saved prompts")
                    .font(.system(size: 24, weight: .semibold))

                Text("Reusable local templates")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(AppTheme.foreground.opacity(0.48))
            }

            Spacer()

            Button {
                isAddingTemplate.toggle()
            } label: {
                Image(systemName: isAddingTemplate ? "minus" : "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 38, height: 38)
                    .background(AppTheme.foreground.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isAddingTemplate ? "Hide new prompt form" : "Add saved prompt")

            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 38, height: 38)
                    .background(AppTheme.foreground.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close saved prompts")
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var searchField: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.foreground.opacity(0.38))

            TextField("Search prompts", text: $searchText)
                .font(.system(size: 14, weight: .regular))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.foreground.opacity(0.36))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear prompt search")
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 40)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppTheme.foreground.opacity(0.055))
                .stroke(AppTheme.foreground.opacity(0.08), lineWidth: 1)
        )
    }

    private var addTemplatePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Title", text: $draftTitle)
                .font(.system(size: 15, weight: .regular))
                .textInputAutocapitalization(.sentences)
                .padding(.horizontal, 12)
                .frame(height: 42)
                .background(fieldBackground)

            TextField("Prompt text", text: $draftText, axis: .vertical)
                .font(.system(size: 15, weight: .regular))
                .lineLimit(4...8)
                .textInputAutocapitalization(.sentences)
                .padding(12)
                .background(fieldBackground)

            Button {
                save(draftTitle, draftText)
                draftTitle = ""
                draftText = ""
                isAddingTemplate = false
            } label: {
                Text("Save prompt")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(canSaveDraft ? AppTheme.primaryAction : AppTheme.foreground.opacity(0.12))
                    .foregroundStyle(canSaveDraft ? AppTheme.primaryActionText : AppTheme.foreground.opacity(0.42))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canSaveDraft)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppTheme.foreground.opacity(0.052))
                .stroke(AppTheme.foreground.opacity(0.09), lineWidth: 1)
        )
    }

    private var templateList: some View {
        LazyVStack(alignment: .leading, spacing: 8) {
            if filteredTemplates.isEmpty {
                Text("No prompts found")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(AppTheme.foreground.opacity(0.4))
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(filteredTemplates) { template in
                    templateRow(template)
                }
            }
        }
    }

    private func templateRow(_ template: PromptTemplate) -> some View {
        Button {
            select(template)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: template.isBuiltIn ? "bookmark" : "bookmark.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.foreground.opacity(0.42))
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(template.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.foreground.opacity(0.9))
                            .lineLimit(1)

                        Text(template.category)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppTheme.foreground.opacity(0.42))
                            .padding(.horizontal, 7)
                            .frame(height: 20)
                            .background(AppTheme.foreground.opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }

                    Text(template.text)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(AppTheme.foreground.opacity(0.5))
                        .lineLimit(3)
                }

                Spacer(minLength: 8)
            }
            .padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppTheme.foreground.opacity(0.045))
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            if !template.isBuiltIn {
                Button(role: .destructive) {
                    delete(template)
                } label: {
                    Label("Delete prompt", systemImage: "trash")
                }
            }
        }
        .accessibilityLabel("\(template.title), \(template.category) prompt")
        .accessibilityHint("Adds this prompt to the composer")
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(AppTheme.foreground.opacity(0.07))
            .stroke(AppTheme.foreground.opacity(0.11), lineWidth: 1)
    }
}
