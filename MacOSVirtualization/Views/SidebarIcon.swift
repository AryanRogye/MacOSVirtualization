//
//  SidebarIcon.swift
//  MacOSVirtualization
//
//  Created by Aryan Rogye on 4/7/26.
//

import SwiftUI

struct SidebarIcon: View {
    
    @State private var isHoveringOverSidebar = false
    var action: () -> Void
    
    var sidebarInnerColor: Color {
        return .white.opacity(
            isHoveringOverSidebar ? 0.15 : 0
        )
    }
    var sidebarOuterColor: Color {
        return .white.opacity(
            isHoveringOverSidebar ? 0.2 : 0
        )
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "sidebar.left")
                .resizable()
                .frame(width: 21, height: 17)
                .padding(.horizontal, 3)
                .padding(.vertical, 3)
                .background {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(sidebarInnerColor)
                        .stroke(sidebarOuterColor)
                }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHoveringOverSidebar = hovering
        }
        .animation(.snappy(duration: 0.2), value: isHoveringOverSidebar)
    }
}
