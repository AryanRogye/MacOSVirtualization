//
//  Sidebar.swift
//  MacOSVirtualization
//
//  Created by Aryan Rogye on 4/7/26.
//

import SwiftUI

struct Sidebar: View {
    
    @Binding var sidebarState: SidebarState
    @Binding var bootIntoRecovery: Bool
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
            ScrollView {
                bootIntoRecoveryView
                    .padding(.top, 64)
                sshView
                    .padding(.horizontal, 6)
            }
            .frame(
                maxWidth: width,
                maxHeight: .infinity
            )
            .background(backgroundColor)
        }
    }
    
    private var bootIntoRecoveryView: some View {
        Toggle("Boot Into Recovery", isOn: $bootIntoRecovery)
            .toggleStyle(.switch)
    }
    
    @State private var hostName: String = ""
    @State private var ipAddress: String = ""
    @State private var dialog: String = ""
    @State private var sshError: String? = nil
    @State private var showSSHError = false
    
    @ViewBuilder
    private var sshView: some View {
        TextField("Host Name", text: $hostName)
        TextField("IP Address", text: $ipAddress)
        TextField("Dialog", text: $dialog)
        Button {
        } label: {
            Text("Send")
        }
        .alert(isPresented: $showSSHError) {
            Alert(
                title: Text("Error"),
                message: Text(sshError ?? "Unkown Error")
            )
        }
    }
}
