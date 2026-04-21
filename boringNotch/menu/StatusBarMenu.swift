import Cocoa

private func L(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
}

class BoringStatusMenu: NSMenu {
    
    var statusItem: NSStatusItem!
    
    override init() {
        super.init()
        
        // Initialize the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = BoringIcon.nsImage(
                "music",
                fallbackSystemName: "music.note",
                accessibilityDescription: "BoringNotch"
            )
            button.action = #selector(showMenu)
        }
        
        // Set up the menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: L("Quit"), action: #selector(quitAction), keyEquivalent: "q"))
        statusItem.menu = menu
    }

}
