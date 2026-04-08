//
//  View+hideTitlebar.swift
//  TestingGrid
//
//  Created by Aryan Rogye on 3/15/26.
//

import SwiftUI

extension View {
    func hideTitlebar() -> some View {
        self
            .background {
                HideTitleBarBackground()
            }
    }
}
private struct HideTitleBarBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> some NSView {
        let v = NSView()
        if let window = NSApplication.shared.windows.first {
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.styleMask.insert(.fullSizeContentView)
//            window.isMovableByWindowBackground = true
        }
        return v
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        
    }
}
