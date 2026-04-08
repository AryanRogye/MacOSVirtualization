//
//  CustomButton.swift
//  MacOSVirtualization
//
//  Created by Aryan Rogye on 4/7/26.
//

import SwiftUI

struct CustomButton: View {
    var icon: String
    var width: CGFloat = 21
    var height: CGFloat = 17
    var action: () -> Void
    
    @State private var hovering = false

    var innerColor: Color {
        return .white.opacity(
            hovering ? 0.15 : 0
        )
    }
    var outerColor: Color {
        return .white.opacity(
            hovering ? 0.2 : 0
        )
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .resizable()
                .frame(width: width, height: height)
                .padding(.horizontal, 3)
                .padding(.vertical, 3)
                .background {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(innerColor)
                        .stroke(outerColor)
                }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            self.hovering = hovering
        }
        .animation(.snappy(duration: 0.2), value: hovering)
    }
}
