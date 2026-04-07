//
//  MacOSVirtualMachineInstaller.swift
//  MacOSVirtualization
//
//  Created by Aryan Rogye on 4/7/26.
//

import Virtualization


enum MacOSVirtualMachineInstallerError: Error {
    case failedToCreateVMBundle
    case failedToInstallMacOS(String)
    case failedToCreateAuxiliaryStorage
    case noSupportedConfigurationAvailable
    case macOSConfigurationIsntSupportedOnTheCurrentHost
    case failedWhileWritingToHardwareModel
    case failedWhileWritingToMachineIdentifier
    case cpuCountIsNotSupportedByConfig
    case memorySizeIsntSupportedByConfig
    case failedToLaunchDiskUtil(String)
    case failedToCreateDiskImage
    case errorWhileValidatingVMConfig(String)
    case errorWhileValidatingSaveRestoreSupport(String)
}

class MacOSVirtualMachineInstaller: NSObject {
    
    private var installationObserver: NSKeyValueObservation?
    private var virtualMachine: VZVirtualMachine!
    private var virtualMachineResponder: MacOSVirtualMachineDelegate?
    
    /// Caller must set this
    public var onInstallProgress: (Double?) -> Void = { p in }
    
    /**
     * Create a bundle on the user's Home directory to store any artifacts
     * that the installation produces.
     */
    public func setUpVirtualMachineArtifacts() throws {
        try createVMBundle()
    }
    
    /**
     * Create a folder that represents a virtual Mac
     * For our testing for now, we will only have 1
     */
    private func createVMBundle() throws {
        if directoryExists(at: Constants.vmBundleURL) {
            return
        }
        do {
            try FileManager.default.createDirectory(
                atPath: Constants.vmBundlePath,
                withIntermediateDirectories: false
            )
        } catch {
            throw MacOSVirtualMachineInstallerError.failedToCreateVMBundle
        }
    }
    
    public func directoryExists(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        if !FileManager.default.fileExists(
            atPath: url.path(),
            isDirectory: &isDirectory
        ) {
            /// this means it doesnt exist at all so just return false
            return false
        }
        return isDirectory.boolValue
    }
    
    /**
     * Install macOS onto the virtual machine from IPSW.
     */
    public func installMacOS(ipswURL: URL, completionHandler: @escaping (Result<Void, Error>) -> Void) {
        VZMacOSRestoreImage.load(from: ipswURL, completionHandler: { [self](result: Result<VZMacOSRestoreImage, Error>) in
            switch result {
                /// something went wrong "call our completion" and return
            case let .failure(error):
                completionHandler(.failure(MacOSVirtualMachineInstallerError.failedToInstallMacOS(error.localizedDescription)))
                return
                
            case let .success(restoreImage):
                installMacOS(restoreImage: restoreImage, completionHandler: completionHandler)
            }
        })
    }
    
    private func installMacOS(
        restoreImage: VZMacOSRestoreImage,
        completionHandler: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let macOSConfiguration = restoreImage.mostFeaturefulSupportedConfiguration else {
            completionHandler(.failure(MacOSVirtualMachineInstallerError.noSupportedConfigurationAvailable))
            return
        }
        
        if !macOSConfiguration.hardwareModel.isSupported {
            completionHandler(.failure(MacOSVirtualMachineInstallerError.macOSConfigurationIsntSupportedOnTheCurrentHost))
            return
        }
        
        DispatchQueue.main.async { [self] in
            do {
                try setupVirtualMachine(
                    macOSConfiguration: macOSConfiguration,
                )
            } catch {
                completionHandler(.failure(error))
                return
            }
            
            startInstallation(
                restoreImageURL: restoreImage.url,
                completionHandler: completionHandler
            )
        }
    }
}

extension MacOSVirtualMachineInstaller {
    private func startInstallation(
        restoreImageURL: URL,
        completionHandler: @escaping (Result<Void, Error>) -> Void
    ) {
        let installer = VZMacOSInstaller(virtualMachine: virtualMachine, restoringFromImageAt: restoreImageURL)
        
        installer.install(completionHandler: { (result: Result<Void, Error>) in
            if case let .failure(error) = result {
                completionHandler(.failure(MacOSVirtualMachineInstallerError.failedToInstallMacOS(error.localizedDescription)))
                return
            } else {
                completionHandler(.success(()))
            }
        })
        
        // Observe installation progress.
        installationObserver = installer.progress.observe(\.fractionCompleted, options: [.initial, .new]) { [weak self] (progress, change) in
            guard let self else { return }
            onInstallProgress((change.newValue ?? 0) * 100)
        }
    }
}

extension MacOSVirtualMachineInstaller {
    /**
     * Create the virtual machine configuration and instantiate the virtual machine.
     */
    private func setupVirtualMachine(
        macOSConfiguration: VZMacOSConfigurationRequirements,
    ) throws {
        let virtualMachineConfiguration = VZVirtualMachineConfiguration()
        
        virtualMachineConfiguration.platform = try createMacPlatformConfiguration(
            macOSConfiguration: macOSConfiguration
        )
        
        virtualMachineConfiguration.cpuCount = MacOSVirtualMachineConfigurationHelper.computeCPUCount()
        if virtualMachineConfiguration.cpuCount < macOSConfiguration.minimumSupportedCPUCount {
            throw MacOSVirtualMachineInstallerError.cpuCountIsNotSupportedByConfig
        }
        
        virtualMachineConfiguration.memorySize = MacOSVirtualMachineConfigurationHelper.computeMemorySize()
        if virtualMachineConfiguration.memorySize < macOSConfiguration.minimumSupportedMemorySize {
            throw MacOSVirtualMachineInstallerError.memorySizeIsntSupportedByConfig
        }
        
        // Create a 128 GB disk image.
        try createDiskImage()
        
        virtualMachineConfiguration.bootLoader = MacOSVirtualMachineConfigurationHelper.createBootLoader()
        
        virtualMachineConfiguration.audioDevices = [MacOSVirtualMachineConfigurationHelper.createSoundDeviceConfiguration()]
        virtualMachineConfiguration.graphicsDevices = [MacOSVirtualMachineConfigurationHelper.createGraphicsDeviceConfiguration()]
        virtualMachineConfiguration.networkDevices = [MacOSVirtualMachineConfigurationHelper.createNetworkDeviceConfiguration()]
        /// throws a error
        virtualMachineConfiguration.storageDevices = [
            try MacOSVirtualMachineConfigurationHelper.createBlockDeviceConfiguration(at: Constants.diskImageURL)
        ]
        
        virtualMachineConfiguration.pointingDevices = [MacOSVirtualMachineConfigurationHelper.createPointingDeviceConfiguration()]
        virtualMachineConfiguration.keyboards = [MacOSVirtualMachineConfigurationHelper.createKeyboardConfiguration()]
        
        do {
            try virtualMachineConfiguration.validate()
        } catch {
            throw MacOSVirtualMachineInstallerError.errorWhileValidatingVMConfig(error.localizedDescription)
        }
        
        do {
            try virtualMachineConfiguration.validateSaveRestoreSupport()
        } catch {
            throw MacOSVirtualMachineInstallerError.errorWhileValidatingSaveRestoreSupport(error.localizedDescription)
        }
        
        virtualMachine = VZVirtualMachine(configuration: virtualMachineConfiguration)
        virtualMachineResponder = MacOSVirtualMachineDelegate()
        virtualMachine.delegate = virtualMachineResponder
    }
    
    private func createMacPlatformConfiguration(
        macOSConfiguration: VZMacOSConfigurationRequirements
    ) throws -> VZMacPlatformConfiguration {
        let macPlatformConfiguration = VZMacPlatformConfiguration()
        
        guard let auxiliaryStorage = try? VZMacAuxiliaryStorage(
            creatingStorageAt: Constants.auxiliaryStorageURL,
            hardwareModel: macOSConfiguration.hardwareModel,
            options: []
        ) else {
            throw MacOSVirtualMachineInstallerError.failedToCreateAuxiliaryStorage
        }
        macPlatformConfiguration.auxiliaryStorage = auxiliaryStorage
        macPlatformConfiguration.hardwareModel = macOSConfiguration.hardwareModel
        macPlatformConfiguration.machineIdentifier = VZMacMachineIdentifier()
        
        // Store the hardware model and machine identifier to disk so that you
        // can retrieve them for subsequent boots.
        do {
            try macPlatformConfiguration.hardwareModel.dataRepresentation.write(to: Constants.hardwareModelURL)
        } catch {
            throw MacOSVirtualMachineInstallerError.failedWhileWritingToHardwareModel
        }
        do {
            try macPlatformConfiguration.machineIdentifier.dataRepresentation.write(to: Constants.machineIdentifierURL)
        } catch {
            throw MacOSVirtualMachineInstallerError.failedWhileWritingToMachineIdentifier
        }
        
        return macPlatformConfiguration
    }
    
    private func createDiskImage() throws {
        try createASIFDiskImage()
    }
    
    // Virtualization framework supports two disk image formats:
    // * RAW disk image: a file that has a 1-to-1 mapping between the offsets in the file and the offsets in the VM disk.
    //   The logical size of a RAW disk image is the size of the disk itself.
    //
    //   In case the image file is stored on an APFS volume, the file will take less space
    //   thanks to the sparse files feature of APFS.
    //
    // * ASIF disk image: A sparse image format. You can transfer ASIF files more efficiently between hosts or disks
    //   as their sparsity doesn’t depend on the host’s filesystem capabilities.
    //
    // The framework supports ASIF since macOS 16.
    @available(macOS 16.0, *)
    private func createASIFDiskImage() throws {
        do {
            let process = try Process.run(URL(fileURLWithPath: "/usr/sbin/diskutil"),
                                          arguments: ["image", "create", "blank",
                                                      "--fs", "none", "--format",
                                                      "ASIF", "--size", "48GiB",
                                                      Constants.diskImageURL.path])
            process.waitUntilExit()
            if process.terminationStatus != 0 {
                throw MacOSVirtualMachineInstallerError.failedToCreateDiskImage
            }
        } catch {
            throw MacOSVirtualMachineInstallerError.failedToLaunchDiskUtil(error.localizedDescription)
        }
    }

}


