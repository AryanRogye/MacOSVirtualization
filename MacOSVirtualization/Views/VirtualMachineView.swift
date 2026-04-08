//
//  VirtualMachineView.swift
//  MacOSVirtualization
//
//  Created by Aryan Rogye on 4/7/26.
//

import SwiftUI

struct VirtualMachineView: View {
    
    @Bindable var vmLoader : VMLoaderCoordinator
    
    var body: some View {
        VMView(vmView: vmLoader.virtualMachineView)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .top
            )
    }
}
