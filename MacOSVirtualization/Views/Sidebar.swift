//
//  Sidebar.swift
//  MacOSVirtualization
//
//  Created by Aryan Rogye on 4/7/26.
//

import SwiftUI

struct Sidebar: View {
    
    @Binding var sidebarState: SidebarState
    let width: CGFloat
    
    var backgroundColor: some ShapeStyle {
        LinearGradient(
            colors: [
                .indigo.mix(with: .black, by: 0.2).opacity(0.7),
                .indigo.mix(with: .purple, by: 0.3).mix(with: .black, by: 0.2).opacity(0.8),
                .indigo.mix(with: .black, by: 0.4).mix(with: .white, by: 0.4).opacity(0.9)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        if sidebarState == .open {
            VStack {
            }
            .frame(
                maxWidth: width,
                maxHeight: .infinity
            )
            .background(backgroundColor)
        }
    }
}
