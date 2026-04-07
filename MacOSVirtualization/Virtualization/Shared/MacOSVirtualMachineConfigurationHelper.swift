//
//  MacOSVirtualMachineConfigurationHelper.swift
//  MacOSVirtualization
//
//  Created by Aryan Rogye on 4/7/26.
//

import Foundation
import Virtualization

enum MacOSVirtualMachineConfigurationHelperError: Error {
    case failedToCreateDiskImage
}

struct MacOSVirtualMachineConfigurationHelper {
    
    /**
     * Function To Compute CPU Count
     * This calculates the amount of CPU cores on the machine this is running on
     * and uses -1
     */
    static func computeCPUCount() -> Int {
        let totalAvailableCPUs = ProcessInfo.processInfo.processorCount

        var virtualCPUCount = totalAvailableCPUs <= 1 ? 1 : totalAvailableCPUs - 1
        virtualCPUCount = max(virtualCPUCount, VZVirtualMachineConfiguration.minimumAllowedCPUCount)
        virtualCPUCount = min(virtualCPUCount, VZVirtualMachineConfiguration.maximumAllowedCPUCount)

        return virtualCPUCount
    }

    /**
     * Set the amount of system memory (4GB)
     */
    static func computeMemorySize() -> UInt64 {
        let memory : UInt64 = 4
        var memorySize = (memory * 1024 * 1024 * 1024) as UInt64
        memorySize = max(memorySize, VZVirtualMachineConfiguration.minimumAllowedMemorySize)
        memorySize = min(memorySize, VZVirtualMachineConfiguration.maximumAllowedMemorySize)

        return memorySize
    }

    /**
     * Creates a Bootloader
     */
    static func createBootLoader() -> VZMacOSBootLoader {
        return VZMacOSBootLoader()
    }

    /**
     * Creates a Virtual Disk and attaches it to the vm
     */
    static func createBlockDeviceConfiguration(
        at url: URL
    ) throws -> VZVirtioBlockDeviceConfiguration {
        guard let diskImageAttachment = try? VZDiskImageStorageDeviceAttachment(url: url, readOnly: false) else {
            throw MacOSVirtualMachineConfigurationHelperError.failedToCreateDiskImage
        }
        let disk = VZVirtioBlockDeviceConfiguration(attachment: diskImageAttachment)
        return disk
    }

    /**
     * defining the virtual display
     */
    static func createGraphicsDeviceConfiguration(
        
    ) -> VZMacGraphicsDeviceConfiguration {
        let graphicsConfiguration = VZMacGraphicsDeviceConfiguration()
        graphicsConfiguration.displays = [
            VZMacGraphicsDisplayConfiguration(widthInPixels: 1920, heightInPixels: 1200, pixelsPerInch: 80)
        ]

        return graphicsConfiguration
    }

    /**
     * Creates a virtual network card
     */
    static func createNetworkDeviceConfiguration(
        
    ) -> VZVirtioNetworkDeviceConfiguration {
        let networkDevice = VZVirtioNetworkDeviceConfiguration()
        networkDevice.macAddress = VZMACAddress(string: "d6:a7:58:8e:78:d4")!

        let networkAttachment = VZNATNetworkDeviceAttachment()
        networkDevice.attachment = networkAttachment

        return networkDevice
    }

    /**
     * Creates a virtual sound device
     */
    static func createSoundDeviceConfiguration(
        
    ) -> VZVirtioSoundDeviceConfiguration {
        let audioConfiguration = VZVirtioSoundDeviceConfiguration()

        let inputStream = VZVirtioSoundDeviceInputStreamConfiguration()
        inputStream.source = VZHostAudioInputStreamSource()

        let outputStream = VZVirtioSoundDeviceOutputStreamConfiguration()
        outputStream.sink = VZHostAudioOutputStreamSink()

        audioConfiguration.streams = [inputStream, outputStream]
        return audioConfiguration
    }

    /**
     * Gives the VM a trackpad-like pointing device
     */
    static func createPointingDeviceConfiguration(
        
    ) -> VZPointingDeviceConfiguration {
        return VZMacTrackpadConfiguration()
    }

    /**
     * Gives the VM a keyboard
     */
    static func createKeyboardConfiguration(
        
    ) -> VZKeyboardConfiguration {
        if #available(macOS 14.0, *) {
            return VZMacKeyboardConfiguration()
        } else {
            return VZUSBKeyboardConfiguration()
        }
    }
}
