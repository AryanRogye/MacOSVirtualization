//
//  VirtualMachineLoader.swift
//  MacOSVirtualization
//
//  Created by Aryan Rogye on 4/7/26.
//

import Virtualization

enum VirtualMachineLoaderError: Error {
    case missingVirtualMachineBundle
    case failedToRetrieveHardwareModelData
    case failedToCreateHardwareModel
    case hardwareModelNotSupported
    case failedToRetrieveMachineIdentifierData
    case failedToCreateMachineIdentifier
}

class VirtualMachineLoader {
    
    public func createVirtualMachine() throws -> VZVirtualMachine {
        let virtualMachineConfiguration = VZVirtualMachineConfiguration()
        
        virtualMachineConfiguration.platform = try createMacPlaform()
        virtualMachineConfiguration.bootLoader = MacOSVirtualMachineConfigurationHelper.createBootLoader()
        virtualMachineConfiguration.cpuCount = MacOSVirtualMachineConfigurationHelper.computeCPUCount()
        virtualMachineConfiguration.memorySize = MacOSVirtualMachineConfigurationHelper.computeMemorySize()
        
        virtualMachineConfiguration.audioDevices = [MacOSVirtualMachineConfigurationHelper.createSoundDeviceConfiguration()]
        virtualMachineConfiguration.graphicsDevices = [MacOSVirtualMachineConfigurationHelper.createGraphicsDeviceConfiguration()]
        virtualMachineConfiguration.networkDevices = [MacOSVirtualMachineConfigurationHelper.createNetworkDeviceConfiguration()]
        
        
        virtualMachineConfiguration.storageDevices = [
            try MacOSVirtualMachineConfigurationHelper.createBlockDeviceConfiguration(at: Constants.diskImageURL)
        ]
        
        virtualMachineConfiguration.pointingDevices = [MacOSVirtualMachineConfigurationHelper.createPointingDeviceConfiguration()]
        virtualMachineConfiguration.keyboards = [MacOSVirtualMachineConfigurationHelper.createKeyboardConfiguration()]
        
        try virtualMachineConfiguration.validate()
        
        try virtualMachineConfiguration.validateSaveRestoreSupport()
        
        return VZVirtualMachine(configuration: virtualMachineConfiguration)
    }
    
    private func createMacPlaform() throws -> VZMacPlatformConfiguration {
        let macPlatform = VZMacPlatformConfiguration()
        
        let auxiliaryStorage = VZMacAuxiliaryStorage(
            contentsOf: Constants.auxiliaryStorageURL
        )
        macPlatform.auxiliaryStorage = auxiliaryStorage
        
        if !FileManager.default.fileExists(atPath: Constants.vmBundlePath) {
            throw VirtualMachineLoaderError.missingVirtualMachineBundle
        }
        
        // Retrieve the hardware model and save this value to disk
        // during installation.
        guard let hardwareModelData = try? Data(
            contentsOf: Constants.hardwareModelURL
        ) else {
            throw VirtualMachineLoaderError.failedToRetrieveHardwareModelData
        }
        
        guard let hardwareModel = VZMacHardwareModel(
            dataRepresentation: hardwareModelData
        ) else {
            throw VirtualMachineLoaderError.failedToCreateHardwareModel
        }
        
        if !hardwareModel.isSupported {
            throw VirtualMachineLoaderError.hardwareModelNotSupported
        }
        macPlatform.hardwareModel = hardwareModel
        
        // Retrieve the machine identifier and save this value to disk
        // during installation.
        guard let machineIdentifierData = try? Data(
            contentsOf: Constants.machineIdentifierURL
        ) else {
            throw VirtualMachineLoaderError.failedToRetrieveMachineIdentifierData
        }
        
        guard let machineIdentifier = VZMacMachineIdentifier(
            dataRepresentation: machineIdentifierData
        ) else {
            throw VirtualMachineLoaderError.failedToCreateMachineIdentifier
        }
        macPlatform.machineIdentifier = machineIdentifier
        
        return macPlatform
    }
    
}
