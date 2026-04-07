//
//  MacOSVirtualMachineDelegate.swift
//  MacOSVirtualization
//
//  Created by Aryan Rogye on 4/7/26.
//

import Virtualization

class MacOSVirtualMachineDelegate: NSObject, VZVirtualMachineDelegate {
    /**
     * Something Went Wrong
     */
    func virtualMachine(
        _ virtualMachine: VZVirtualMachine,
        didStopWithError error: Error
    ) {
        NSLog("Virtual machine did stop with error: \(error.localizedDescription)")
        exit(-1)
    }
    
    /**
     * User Stopped
     */
    func guestDidStop(
        _ virtualMachine: VZVirtualMachine
    ) {
        NSLog("Guest did stop virtual machine.")
        exit(0)
    }
}
