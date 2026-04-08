//
//  TopBar.swift
//  MacOSVirtualization
//
//  Created by Aryan Rogye on 4/7/26.
//

import SwiftUI

struct TopBar<SidebarIcon: View>: View {
    
    @Binding var shouldShowSidebarIcon: Bool
    let height: CGFloat
    @ViewBuilder var sidebarIcon: () -> SidebarIcon

    var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: 8,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: 8,
        )
    }
    
    var body: some View {
        HStack {
            if shouldShowSidebarIcon {
                sidebarIcon()
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .foregroundStyle(.black)
        .frame(maxWidth: .infinity, maxHeight: 40)
        .background(.regularMaterial)
    }
}
