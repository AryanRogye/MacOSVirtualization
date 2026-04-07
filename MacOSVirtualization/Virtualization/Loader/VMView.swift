//
//  VMView.swift
//  MacOSVirtualization
//
//  Created by Aryan Rogye on 4/7/26.
//

import SwiftUI
import Virtualization

struct VMView: NSViewRepresentable {
    let vmView: VZVirtualMachineView
    
    func makeNSView(context: Context) -> VZVirtualMachineView {
        vmView
    }
    
    func updateNSView(_ nsView: VZVirtualMachineView, context: Context) {}
}
