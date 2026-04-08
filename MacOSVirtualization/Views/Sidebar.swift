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
    @Bindable var sshCoordinator: SSHCoordinator
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
    
    @ViewBuilder
    private var sshView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Guest SSH")
                .font(.headline)

            TextField("Guest IP Address", text: $sshCoordinator.address)
                .textFieldStyle(.roundedBorder)

            TextField("Username", text: $sshCoordinator.username)
                .textFieldStyle(.roundedBorder)

            SecureField("Password", text: $sshCoordinator.password)
                .textFieldStyle(.roundedBorder)

            TextField("Port", text: $sshCoordinator.port)
                .textFieldStyle(.roundedBorder)

            TextField("Pinned Host Key", text: $sshCoordinator.hostPublicKey, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)

            Button("Copy ssh-keyscan Command") {
                sshCoordinator.copyHostKeyscanCommand()
            }

            Text(sshCoordinator.hostKeyscanCommand)
                .font(.caption.monospaced())
                .textSelection(.enabled)
                .foregroundStyle(.white.opacity(0.75))

            Text("Command")
                .font(.subheadline.weight(.medium))

            TextEditor(text: $sshCoordinator.command)
                .frame(minHeight: 80)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                .font(.system(.body, design: .monospaced))

            Button {
                sshCoordinator.runCommand()
            } label: {
                Text(sshCoordinator.isRunning ? "Running..." : "Run Command")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(sshCoordinator.isRunning)

            Text(sshCoordinator.status)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.8))

            if !sshCoordinator.output.isEmpty {
                Text("Output")
                    .font(.subheadline.weight(.medium))

                ScrollView {
                    Text(sshCoordinator.output)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .foregroundStyle(.white.opacity(0.9))
                }
                .frame(minHeight: 120)
                .padding(8)
                .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}
