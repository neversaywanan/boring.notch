//
//  AppIcons.swift
//  boringNotch
//
//  Created by Harsh Vardhan  Goswami  on 16/08/24.
//

import SwiftUI
import AppKit
import LucideIcons

struct AppIcons {
    
    func getIcon(file path: String) -> NSImage? {
        guard FileManager.default.fileExists(atPath: path)
        else { return nil }
        
        return NSWorkspace.shared.icon(forFile: path)
    }
    
    func getIcon(bundleID: String) -> NSImage? {
        guard let path = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: bundleID
        )?.absoluteString
        else { return nil }
        
        return getIcon(file: path)
    }
    
        /// Easily read Info.plist as a Dictionary from any bundle by accessing .infoDictionary on Bundle
    func bundle(forBundleID: String) -> Bundle? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: forBundleID)
        else { return nil }
        
        return Bundle(url: url)
    }
    
}

func AppIcon(for bundleID: String) -> Image {
    let workspace = NSWorkspace.shared
    
    if let appURL = workspace.urlForApplication(withBundleIdentifier: bundleID) {
        let appIcon = workspace.icon(forFile: appURL.path)
        return Image(nsImage: appIcon)
    }
    
    return Image(nsImage: workspace.icon(for: .applicationBundle))
}


func AppIconAsNSImage(for bundleID: String) -> NSImage? {
    let workspace = NSWorkspace.shared
    
    if let appURL = workspace.urlForApplication(withBundleIdentifier: bundleID) {
        let appIcon = workspace.icon(forFile: appURL.path)
        appIcon.size = NSSize(width: 256, height: 256)
        return appIcon
    }
    return nil
}

enum BoringIcon {
    static func image(_ lucideId: String, fallbackSystemName: String) -> Image {
        Image(nsImage: nsImage(lucideId, fallbackSystemName: fallbackSystemName))
            .renderingMode(.template)
    }

    static func nsImage(
        _ lucideId: String,
        fallbackSystemName: String,
        accessibilityDescription: String? = nil
    ) -> NSImage {
        if let lucideImage = NSImage.image(lucideId: lucideId) {
            let image = (lucideImage.copy() as? NSImage) ?? lucideImage
            image.isTemplate = true
            return image
        }

        if let systemImage = NSImage(
            systemSymbolName: fallbackSystemName,
            accessibilityDescription: accessibilityDescription
        ) {
            return systemImage
        }

        return NSImage(size: NSSize(width: 16, height: 16))
    }
}
