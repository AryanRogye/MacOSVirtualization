//
//  MacOSVirtualizationApp.swift
//  MacOSVirtualization
//
//  Created by Aryan Rogye on 4/7/26.
//

import SwiftUI

@main
struct MacOSVirtualizationApp: App {
    var body: some Scene {
        WindowGroup {
            VMScreen()
        }
        .windowStyle(.hiddenTitleBar)
    }
}
