//
//  ContentView.swift
//  MacOSVirtualization
//
//  Created by Aryan Rogye on 4/7/26.
//

import SwiftUI

struct ContentView: View {
    
    @State private var installerCoordinator = InstallerCoordinator()
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color.blue.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                VStack(alignment: .leading, spacing: 20) {
                    header
                    
                    Divider()
                    
                    phaseSection
                    
                    if let progress = installerCoordinator.downloadProgress,
                       installerCoordinator.installerPhase == .downloadingRestoreImage {
                        progressSection(
                            title: "Downloading Restore Image",
                            value: progress
                        )
                    }
                    
                    if let progress = installerCoordinator.installProgress,
                       installerCoordinator.installerPhase == .installingMacOS {
                        progressSection(
                            title: "Installing macOS",
                            value: progress
                        )
                    }
                    
                    statusSection
                    
                    actions
                }
                .padding(28)
                .frame(maxWidth: 520)
                .background {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.regularMaterial)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(.white.opacity(0.12))
                }
                .shadow(radius: 20, y: 10)
                
                Spacer()
            }
            .padding(32)
        }
        .alert("Installation Error", isPresented: $installerCoordinator.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(installerCoordinator.error ?? "Something went wrong.")
        }
    }
}

private extension ContentView {
    
    var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "macwindow.badge.plus")
                    .font(.system(size: 28, weight: .semibold))
                
                Text("macOS Virtual Machine")
                    .font(.system(size: 28, weight: .bold))
            }
            
            Text("Create and install a macOS virtual machine using Apple’s Virtualization framework.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
    
    var phaseSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Phase")
                .font(.headline)
            
            HStack(spacing: 10) {
                Circle()
                    .fill(phaseColor)
                    .frame(width: 10, height: 10)
                
                Text(installerCoordinator.installerPhase.rawValue)
                    .font(.body.weight(.medium))
            }
        }
    }
    
    var statusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Status")
                .font(.headline)
            
            statusRow(
                title: "Needs Install",
                value: installerCoordinator.doesNeedToInstall ? "Yes" : "No"
            )
            
            statusRow(
                title: "Download Progress",
                value: percentString(installerCoordinator.downloadProgress)
            )
            
            statusRow(
                title: "Install Progress",
                value: percentString(installerCoordinator.installProgress)
            )
        }
    }
    
    var actions: some View {
        VStack {
            HStack {
                NavigationLink(destination: VMScreen()) {
                    HStack {
                        Image(systemName: "macbook")
                        Text("Run VM")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isBusy || installerCoordinator.doesNeedToInstall)
            }
            HStack(spacing: 12) {
                Button {
                    installerCoordinator.install()
                } label: {
                    HStack {
                        Image(systemName: "arrow.down.app")
                        Text(buttonTitle)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isBusy || !installerCoordinator.doesNeedToInstall)
                
                if installerCoordinator.installerPhase == .complete {
                    Label("Done", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.headline)
                }
            }
        }
    }
    
    func progressSection(title: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(value))%")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            
            ProgressView(value: value, total: 100)
                .progressViewStyle(.linear)
        }
    }
    
    func statusRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .monospacedDigit()
        }
        .font(.subheadline)
    }
    
    func percentString(_ value: Double?) -> String {
        guard let value else { return "--" }
        return "\(Int(value))%"
    }
    
    var isBusy: Bool {
        installerCoordinator.installerPhase == .setupVMArtifacts ||
        installerCoordinator.installerPhase == .downloadingRestoreImage ||
        installerCoordinator.installerPhase == .installingMacOS
    }
    
    var buttonTitle: String {
        switch installerCoordinator.installerPhase {
        case .idle:
            return "Install macOS"
        case .setupVMArtifacts:
            return "Setting Up..."
        case .downloadingRestoreImage:
            return "Downloading..."
        case .installingMacOS:
            return "Installing..."
        case .complete:
            return "Installed"
        }
    }
    
    var phaseColor: Color {
        switch installerCoordinator.installerPhase {
        case .idle:
            return .gray
        case .setupVMArtifacts:
            return .orange
        case .downloadingRestoreImage:
            return .blue
        case .installingMacOS:
            return .purple
        case .complete:
            return .green
        }
    }
}

#Preview {
    ContentView()
}
