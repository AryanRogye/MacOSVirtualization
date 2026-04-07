//
//  Constants.swift
//  MacOSVirtualization
//
//  Created by Aryan Rogye on 4/7/26.
//

import Foundation

enum Constants {
    static let vmBundlePath = NSHomeDirectory() + "/VM.bundle/"
    /// URL
    static let vmBundleURL = URL(fileURLWithPath: vmBundlePath)
    
    /// URL with restore Image
    static let restoreImageURL = Self.vmBundleURL.appendingPathComponent("RestoreImage.ipsw")
    
    /// URL with AuxiliaryStorage
    static let auxiliaryStorageURL = Self.vmBundleURL.appendingPathComponent("AuxiliaryStorage")
    
    /// URL with HardwareModel
    static let hardwareModelURL = vmBundleURL.appendingPathComponent("HardwareModel")
    
    /// URL with MachineIdentifier
    static let machineIdentifierURL = vmBundleURL.appendingPathComponent("MachineIdentifier")
    
    /// URL for Disk Image
    static let diskImageURL = vmBundleURL.appendingPathComponent("Disk.img")
    
    /// URL for SaveFile
    static let saveFileURL = vmBundleURL.appendingPathComponent("SaveFile.vzvmsave")
}
