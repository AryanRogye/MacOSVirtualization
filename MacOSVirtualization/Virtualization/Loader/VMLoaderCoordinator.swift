//
//  VMLoaderCoordinator.swift
//  MacOSVirtualization
//
//  Created by Aryan Rogye on 4/7/26.
//

import Virtualization
import SwiftUI

@Observable
@MainActor
class VMLoaderCoordinator {
    
    private var virtualMachineResponder: MacOSVirtualMachineDelegate?
    private var virtualMachine: VZVirtualMachine?
    var virtualMachineView = VZVirtualMachineView()
    
    var error: String?
    var showError = false
    
    let loader = VirtualMachineLoader()
    
    var bootIntoRecovery: Bool = false
    
    var isPaused: Bool {
        virtualMachine?.state == .paused
    }
    
    public func load() {
        do {
            let machine = try loader.createVirtualMachine()
            let responder = MacOSVirtualMachineDelegate()
            machine.delegate = responder
            
            virtualMachineView.virtualMachine = machine
            virtualMachineView.capturesSystemKeys = true
            virtualMachineView.automaticallyReconfiguresDisplay = true
            
            self.virtualMachine = machine
            self.virtualMachineResponder = responder
            
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: Constants.saveFileURL.path) {
                restoreVirtualMachine()
            } else {
                startVirtualMachine()
            }
        } catch let e as VirtualMachineLoaderError {
            switch e {
            case .missingVirtualMachineBundle:
                error = "Missing Virtual Machine Bundle"
            case .failedToRetrieveHardwareModelData:
                error = "Failed To Retreive Hardware Model Data"
            case .failedToCreateHardwareModel:
                error = "Failed To Create Hardware Model"
            case .hardwareModelNotSupported:
                error = "Hardware Model Not Supported"
            case .failedToRetrieveMachineIdentifierData:
                error = "Failed To Retreive Machine Identifier Data"
            case .failedToCreateMachineIdentifier:
                error = "Failed To Create Machine Identifier"
            }
            showError = true
        } catch {
            self.error = error.localizedDescription
            showError = true
        }
    }
    
    func restoreVirtualMachine() {
        guard let virtualMachine else { return }
        virtualMachine.restoreMachineStateFrom(
            url: Constants.saveFileURL,
            completionHandler: { [self] (error) in
                // Remove the saved file. Whether success or failure, the state no longer matches the VM's disk.
                let fileManager = FileManager.default
                do {
                    try fileManager.removeItem(at: Constants.saveFileURL)
                } catch {
                    self.error = error.localizedDescription
                    self.showError = true
                    return
                }
                
                if error == nil {
                    self.resumeVirtualMachine()
                } else {
                    self.startVirtualMachine()
                }
            })
    }
    
    func startVirtualMachine() {
        guard let virtualMachine else { return }
        
        if bootIntoRecovery {
            let options = VZMacOSVirtualMachineStartOptions()
            options.startUpFromMacOSRecovery = true
            
            virtualMachine.start(options: options) { error in
                if let error {
                    self.error = "Virtual machine failed to start in Recovery: \(error.localizedDescription)"
                    self.showError = true
                }
            }
        } else {
            virtualMachine.start(completionHandler: { (result) in
                if case let .failure(error) = result {
                    self.error = "Virtual machine failed to start with \(error)"
                    self.showError = true
                }
            })
        }
    }
    
    func reloadVirtualMachine() {
        stopVirtualMachine { [weak self] in
            guard let self else { return }
            
            self.virtualMachineView.virtualMachine = nil
            self.virtualMachine = nil
            self.virtualMachineResponder = nil
            
            self.load()
        }
    }
    
    func playVirtualMachine() {
        guard let virtualMachine else { return }
        virtualMachine.restoreMachineStateFrom(url: Constants.saveFileURL) { error in
            if let error {
                self.error = "Failed to restore machine state: \(error.localizedDescription)"
                self.showError = true
                return
            }
        }
        resumeVirtualMachine()
    }
    
    func pauseVirtualMachine() {
        guard let virtualMachine else { return }
        virtualMachine.pause { result in
            switch result {
            case .success(_):
                break
            case .failure(let e):
                self.error = e.localizedDescription
                self.showError = true
                return
            }
        }
        virtualMachine.saveMachineStateTo(url: Constants.saveFileURL) { error in
            if let error {
                self.error = error.localizedDescription
                self.showError = true
            }
        }
    }
    
    func resumeVirtualMachine() {
        guard let virtualMachine else { return }
        virtualMachine.resume(completionHandler: { (result) in
            if case let .failure(error) = result {
                self.error = "Virtual machine failed to resume with \(error)"
                self.showError = true
            }
        })
    }
    
    func stopVirtualMachine(completion: (() -> Void)? = nil) {
        guard let virtualMachine else { return }
        
        virtualMachine.stop { e in
            if let e {
                self.error = e.localizedDescription
                self.showError = true
            } else {
                completion?()
            }
        }
    }
}
