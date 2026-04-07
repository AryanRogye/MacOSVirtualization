//
//  Virtualization.swift
//  MacOSVirtualization
//
//  Created by Aryan Rogye on 4/7/26.
//

import Foundation
import Virtualization

enum VirtualizationError: Error {
    case noConfig
    case failedToStart(String)
}

class Virtualization {
    
    var config: VZVirtualMachineConfiguration?
    
    public func runVM() async throws {
        guard let config else {
            throw VirtualizationError.noConfig
        }
        
        let virtualMachine = VZVirtualMachine(configuration: config)
        
        do {
            try await virtualMachine.start()
        } catch {
            throw VirtualizationError.failedToStart(error.localizedDescription)
        }
    }
    
    public func makeConfig() {
        var config = VZVirtualMachineConfiguration()
        config.cpuCount = 4
        config.memorySize = (4 * 1024 * 1024 * 1024) as UInt64
        config.storageDevices = []
        config.pointingDevices = []
        self.config = config
        //        config.storageDevices = [newBlockDevice()]
        //        config.pointingDevices = [newPointingDevice()]
    }
}
