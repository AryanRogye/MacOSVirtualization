//
//  InstallerCoordinator.swift
//  MacOSVirtualization
//
//  Created by Aryan Rogye on 4/7/26.
//

import Foundation

enum InstallerPhase: String {
    case idle = "Idle"
    case setupVMArtifacts = "Setting Up VM Artifacts"
    case downloadingRestoreImage = "Attempting to download latest available restore image."
    case installingMacOS
    case complete
}

@Observable
@MainActor
class InstallerCoordinator {
    
    var installerPhase: InstallerPhase = .idle
    let installer = MacOSVirtualMachineInstaller()
    
    var downloadProgress: Double?
    var installProgress: Double?
    var error: String?
    var showError = false
    
    var doesNeedToInstall = true
    
    init() {
        /// if files exist we dont need to install
        doesNeedToInstall = !self.filesExist()
    }
    
    public func install() {
        
        doesNeedToInstall = !self.filesExist()
        guard doesNeedToInstall else { return }
        
        /// Set our installation phase to setting up artifacts
        /// then we tell our installer to setup the virtual machine artifacts
        /// if something goes wrong we set our error flags and return
        installerPhase = .setupVMArtifacts
        do {
            try installer.setUpVirtualMachineArtifacts()
        } catch let e as MacOSVirtualMachineInstallerError {
            handleMacOSVirtualMachineInstallerError(e)
            return
        } catch {
            self.error = error.localizedDescription
            showError = true
            return
        }
        
        /// Set our installation phase to downloading restore image
        /// and set our objects
        installerPhase = .downloadingRestoreImage
        let restoreImage = MacOSRestoreImage()
        
        /// we setup what happens when our download progress is valid
        restoreImage.onDownloadProgress = { [weak self] progress in
            guard let self else { return }
            downloadProgress = progress
        }
        
        /// we start the download, the result is the completion
        /// handler
        restoreImage.download { [weak self] result in
            guard let self else { return }
            
            switch result {
                /// Install MacOS
            case .success(_):
                installMacOS()
                
                /// Handles Errors
            case .failure(let e):
                if let e = e as? MacOSRestoreImageError {
                    handleMacOSRestoreImageError(e)
                }
                else if let e = e as? MacOSVirtualMachineConfigurationHelperError {
                    handleMacOSVirtualMachineConfigurationHelperError(e)
                } else {
                    error = e.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    func filesExist() -> Bool {
        let fm = FileManager.default
        
        return fm.fileExists(atPath: Constants.diskImageURL.path) &&
        fm.fileExists(atPath: Constants.hardwareModelURL.path) &&
        fm.fileExists(atPath: Constants.machineIdentifierURL.path)
    }
    
    private func installMacOS() {
        installerPhase = .installingMacOS
        installer.onInstallProgress = { [weak self] progress in
            guard let self else { return }
            installProgress = progress
        }
        installer.installMacOS(ipswURL: Constants.restoreImageURL) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success():
                installerPhase = .complete
                print("Success")
            case .failure(let e):
                if let e = e as? MacOSVirtualMachineInstallerError {
                    handleMacOSVirtualMachineInstallerError(e)
                }
            }
        }
    }
    
    // MARK: - Error Handling
    
    private func handleMacOSVirtualMachineConfigurationHelperError(_ e: MacOSVirtualMachineConfigurationHelperError) {
        switch e {
        case .failedToCreateDiskImage:
            error = "Failed To Create Disk Image"
        }
        showError = true
    }
    private func handleMacOSRestoreImageError(_ e: MacOSRestoreImageError) {
        switch e {
        case .failedToMoveDownloadedRestoreImage(let reason):
            error = "Failed To Move Downloaded Restore Image: \(reason)"
        case .localURLInvalid:
            error = "Local URL Invalid"
        }
        showError = true
    }
    
    private func handleMacOSVirtualMachineInstallerError(_ e: MacOSVirtualMachineInstallerError) {
        switch e {
        case .failedToCreateVMBundle:
            error = "Failed To Create VM Bundle"
        case .failedToInstallMacOS(let reason):
            error = "Failed To Install MacOS: \(reason)"
        case .failedToCreateAuxiliaryStorage:
            error = "Failed To Create Auxiliary Storage"
        case .noSupportedConfigurationAvailable:
            error = "No Supported Configuration Available"
        case .macOSConfigurationIsntSupportedOnTheCurrentHost:
            error = "MacOS Configuration Isn't Supported On The Current Host"
        case .failedWhileWritingToHardwareModel:
            error = "Failed While Writing To Hardware Model"
        case .failedWhileWritingToMachineIdentifier:
            error = "Failed While Writing To Machine Identifier"
        case .cpuCountIsNotSupportedByConfig:
            error = "CPU Count Is Not Supported By Config"
        case .memorySizeIsntSupportedByConfig:
            error = "Memory Size Isn't Supported By Config"
        case .failedToLaunchDiskUtil(let reason):
            error = "Failed To Launch Disk Util: \(reason)"
        case .failedToCreateDiskImage:
            error = "Failed To Create Disk Image"
        case .errorWhileValidatingVMConfig(let reason):
            error = "Error While Validating VM Config: \(reason)"
        case .errorWhileValidatingSaveRestoreSupport(let reason):
            error = "Error While Validating Save Restore Support: \(reason)"
        }
        showError = true
    }
}
