//
//  VMScreen.swift
//  MacOSVirtualization
//
//  Created by Aryan Rogye on 4/7/26.
//

import SwiftUI

struct VMScreen: View {
    
    @State private var vmLoader = VMLoaderCoordinator()
    
    var body: some View {
        VStack {
            VMView(vmView: vmLoader.virtualMachineView)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .task {
            vmLoader.load()
        }
        .alert(isPresented: $vmLoader.showError) {
            Alert(
                title: Text("Error"),
                message: Text(vmLoader.error ?? "Unkown Error")
            )
        }
    }
}

