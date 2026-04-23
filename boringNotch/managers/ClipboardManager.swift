//
//  ClipboardManager.swift
//  boringNotch
//
//  Created by Antigravity on 2026-04-23.
//

import AppKit
import Combine
import Defaults
import SwiftUI

/// Represents a single clipboard history entry.
struct ClipboardItem: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let timestamp: Date
    let type: ClipboardItemType

    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.id == rhs.id
    }
}

enum ClipboardItemType: String {
    case text
    case url
    case filePath
}

/// Monitors the system pasteboard and maintains a history of clipboard items.
@MainActor
class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()

    @Published var items: [ClipboardItem] = []
    @Published var isMonitoring: Bool = false

    private var timer: Timer?
    private var lastChangeCount: Int = 0

    private init() {
        lastChangeCount = NSPasteboard.general.changeCount
        startMonitoring()
    }



    /// Start polling the system pasteboard for changes.
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        lastChangeCount = NSPasteboard.general.changeCount

        // Poll every 0.5 seconds – lightweight and reliable
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkPasteboard()
            }
        }
    }

    /// Stop monitoring the pasteboard.
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }

    /// Check if the pasteboard contents have changed and capture new items.
    private func checkPasteboard() {
        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount

        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount

        guard Defaults[.clipboardEnabled] else { return }

        // Try to read string content from the pasteboard
        guard let content = pasteboard.string(forType: .string), !content.isEmpty else { return }

        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Avoid duplicates – skip if the top item has the same content
        if let topItem = items.first, topItem.content == trimmed {
            return
        }

        // Determine item type
        let type: ClipboardItemType
        if let url = URL(string: trimmed), url.scheme != nil, url.host != nil {
            type = .url
        } else if FileManager.default.fileExists(atPath: trimmed) {
            type = .filePath
        } else {
            type = .text
        }

        let newItem = ClipboardItem(content: trimmed, timestamp: Date(), type: type)

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            items.insert(newItem, at: 0)
        }

        // Enforce maximum history count
        let maxCount = Defaults[.clipboardMaxItems]
        if items.count > maxCount {
            items = Array(items.prefix(maxCount))
        }
    }

    /// Copy a specific history item back to the system clipboard.
    func copyToClipboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.content, forType: .string)
        // Update change count so we don't re-capture our own paste
        lastChangeCount = pasteboard.changeCount
    }

    /// Remove a specific item from history.
    func removeItem(_ item: ClipboardItem) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            items.removeAll { $0.id == item.id }
        }
    }

    /// Clear all clipboard history.
    func clearAll() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            items.removeAll()
        }
    }
}
