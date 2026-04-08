//
//  SSHCoordinator.swift
//  MacOSVirtualization
//
//  Created by Codex on 4/7/26.
//

import Foundation
import RebuildMeKit
import AppKit

@Observable
@MainActor
final class SSHCoordinator {
    var address: String = ""
    var username: String = ""
    var password: String = ""
    var hostPublicKey: String = ""
    var port: String = "22"
    var command: String = "whoami"
    var output: String = ""
    var status: String = "Configure guest SSH access, then run a command."
    var isRunning: Bool = false

    private let transport = NIOSSHTransport()

    var hostKeyscanCommand: String {
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let target = trimmedAddress.isEmpty ? "<guest-ip>" : trimmedAddress
        return "ssh-keyscan -t ed25519 \(target) | awk '{print $2\" \"$3}'"
    }

    func runCommand() {
        let trimmedCommand = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCommand.isEmpty else {
            status = "Enter a command to run."
            return
        }

        let host = makeHost()
        guard !host.address.isEmpty else {
            status = "Enter the guest IP address."
            return
        }
        guard !host.username.isEmpty else {
            status = "Enter the guest username."
            return
        }
        guard host.password?.isEmpty == false else {
            status = "Enter the guest password."
            return
        }
        guard host.hostPublicKey?.isEmpty == false else {
            status = "Paste the guest SSH host public key."
            return
        }

        isRunning = true
        status = "Running over SSH..."
        output = ""

        Task {
            do {
                let result = try await transport.run(command: trimmedCommand, on: host)
                let combinedOutput = [result.stdout, result.stderr]
                    .filter { !$0.isEmpty }
                    .joined(separator: "\n")

                output = combinedOutput.isEmpty ? "No output returned." : combinedOutput
                status = result.isSuccess
                    ? "SSH command completed."
                    : "SSH command failed with code \(result.exitCode)."
            } catch {
                output = error.localizedDescription
                status = "SSH command failed."
            }

            isRunning = false
        }
    }

    func copyHostKeyscanCommand() {
        #if canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(hostKeyscanCommand, forType: .string)
        status = "Host key command copied to clipboard."
        #else
        status = "Clipboard is unavailable on this platform."
        #endif
    }

    private func makeHost() -> SSHHost {
        SSHHost(
            nickname: "VM Guest",
            address: address.trimmingCharacters(in: .whitespacesAndNewlines),
            username: username.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : password,
            hostPublicKey: normalizeHostPublicKeyInput(hostPublicKey),
            port: Int(port.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 22
        )
    }

    private func normalizeHostPublicKeyInput(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let parts = trimmed.split(whereSeparator: { $0.isWhitespace })

        if parts.count >= 2, parts[0].hasPrefix("ssh-") {
            return "\(parts[0]) \(parts[1])"
        }

        if parts.count >= 3, !parts[0].hasPrefix("ssh-"), parts[1].hasPrefix("ssh-") {
            return "\(parts[1]) \(parts[2])"
        }

        return trimmed
    }
}
