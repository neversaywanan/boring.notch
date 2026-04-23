//
//  ClipboardView.swift
//  boringNotch
//
//  Created by Antigravity on 2026-04-23.
//

import Defaults
import SwiftUI

private func L(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
}

struct ClipboardView: View {
    @EnvironmentObject var vm: BoringViewModel
    @ObservedObject var clipboardManager = ClipboardManager.shared

    @State private var hoveredItemID: UUID?
    @State private var copiedItemID: UUID?
    @State private var isPresented = false

    private let entryAnimation = Animation.interactiveSpring(
        response: 0.34, dampingFraction: 0.72, blendDuration: 0)

    var body: some View {
        VStack(spacing: 0) {


            // Content
            if clipboardManager.items.isEmpty {
                emptyState
            } else {
                itemsList
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(
                    .linearGradient(
                        colors: [.white.opacity(0.4), .white.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text(L("No clipboard history"))
                .foregroundStyle(.gray)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.medium)

            Text(L("Copied text will appear here"))
                .foregroundStyle(.gray.opacity(0.6))
                .font(.system(.caption, design: .rounded))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Items List

    private var itemsList: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 4) {
                ForEach(clipboardManager.items) { item in
                    ClipboardItemRow(
                        item: item,
                        isHovered: hoveredItemID == item.id,
                        isCopied: copiedItemID == item.id,
                        onCopy: {
                            clipboardManager.copyToClipboard(item)
                            withAnimation(.easeInOut(duration: 0.2)) {
                                copiedItemID = item.id
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                withAnimation { copiedItemID = nil }
                            }
                        },
                        onDelete: {
                            clipboardManager.removeItem(item)
                        }
                    )
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            hoveredItemID = hovering ? item.id : nil
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .scrollIndicators(.never)
    }
}

// MARK: - Clipboard Item Row

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let isHovered: Bool
    let isCopied: Bool
    let onCopy: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // Type icon
            typeIcon
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(iconBackgroundColor)
                )

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(item.content)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(2)
                    .truncationMode(.tail)

                Text(relativeTimeString(from: item.timestamp))
                    .font(.system(size: 9, design: .rounded))
                    .foregroundColor(.white.opacity(0.3))
            }

            Spacer(minLength: 4)

            // Actions
            if isHovered || isCopied {
                HStack(spacing: 4) {
                    if isCopied {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Button(action: onCopy) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 24, height: 24)
                                .background(
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(Color.white.opacity(0.1))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Copy")
                        .transition(.scale.combined(with: .opacity))

                        Button(action: onDelete) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: 24, height: 24)
                                .background(
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(Color.white.opacity(0.06))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Remove")
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.white.opacity(0.06) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onCopy()
        }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }

    @ViewBuilder
    private var typeIcon: some View {
        switch item.type {
        case .url:
            Image(systemName: "link")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.blue)
        case .filePath:
            Image(systemName: "doc")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.orange)
        case .text:
            Image(systemName: "text.alignleft")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    private var iconBackgroundColor: Color {
        switch item.type {
        case .url:
            return Color.blue.opacity(0.15)
        case .filePath:
            return Color.orange.opacity(0.15)
        case .text:
            return Color.white.opacity(0.06)
        }
    }

    private func relativeTimeString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 5 {
            return NSLocalizedString("Just now", comment: "")
        } else if interval < 60 {
            return String(format: NSLocalizedString("%.0fs ago", comment: ""), interval)
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return String(format: NSLocalizedString("%dm ago", comment: ""), minutes)
        } else {
            let hours = Int(interval / 3600)
            return String(format: NSLocalizedString("%dh ago", comment: ""), hours)
        }
    }
}
