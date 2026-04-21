//
//  BoringExtrasMenu.swift
//  boringNotch
//
//  Created by Harsh Vardhan  Goswami  on 04/08/24.
//

import SwiftUI

private func L(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
}

struct BoringLargeButtons: View {
    var action: () -> Void
    var icon: Image
    var title: String
    var body: some View {
        Button (
            action:action,
            label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 12.0).fill(.black).frame(width: 70, height: 70)
                    VStack(spacing: 8) {
                        icon.resizable()
                            .aspectRatio(contentMode: .fit).frame(width:20)
                        Text(title).font(.body)
                    }
                }
            }).buttonStyle(PlainButtonStyle()).shadow(color: .black.opacity(0.5), radius: 10)
    }
}

struct BoringExtrasMenu : View {
    @ObservedObject var vm: BoringViewModel
    
    var body: some View {
        VStack{
            HStack(spacing: 20)  {
                hide
                settings
                close
            }
        }
    }
    
    var github: some View {
        BoringLargeButtons(
            action: {
                if let url = URL(string: "https://github.com/TheBoredTeam/boring.notch") {
                    NSWorkspace.shared.open(url)
                }
            },
            icon: Image(.github),
            title: L("Checkout")
        )
    }
    
    var settings: some View {
        Button(action: {
            DispatchQueue.main.async {
                SettingsWindowController.shared.showWindow()
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 12.0).fill(.black).frame(width: 70, height: 70)
                VStack(spacing: 8) {
                    BoringIcon.image("settings", fallbackSystemName: "gear").resizable()
                        .aspectRatio(contentMode: .fit).frame(width:20)
                    Text(L("Settings")).font(.body)
                }
            }
        }
        .buttonStyle(PlainButtonStyle()).shadow(color: .black.opacity(0.5), radius: 10)
    }
    
    var hide: some View {
        BoringLargeButtons(
            action: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    //vm.openMusic()
                }
            },
            icon: BoringIcon.image("minimize", fallbackSystemName: "arrow.down.forward.and.arrow.up.backward"),
            title: L("Hide")
        )
    }
    
    var close: some View {
        BoringLargeButtons(
            action: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        NSApp.terminate(nil)
                    }
                }
            },
            icon: BoringIcon.image("x", fallbackSystemName: "xmark"),
            title: L("Exit")
        )
    }
}


#Preview {
    BoringExtrasMenu(vm: .init())
}
