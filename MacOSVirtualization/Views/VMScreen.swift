//
//  VMScreen.swift
//  MacOSVirtualization
//
//  Created by Aryan Rogye on 4/7/26.
//

import SwiftUI

struct VMScreen: View {
    
    @State private var vmLoader = VMLoaderCoordinator()
    @State private var showInspector: Bool = false
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var sidebarState: SidebarState = .open
    @State private var appViewState: AppViewState = .home
    
    var spacing: CGFloat {
        6
    }
    
    var backgroundColor: some ShapeStyle {
        LinearGradient(
            colors: [
                .indigo.mix(with: .black, by: 0.2).opacity(0.5),
                .indigo.mix(with: .purple, by: 0.3).mix(with: .black, by: 0.2).opacity(0.6),
                .indigo.mix(with: .black, by: 0.4).opacity(0.9)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var topBarHeight: CGFloat { 40 }
    
    var body: some View {
        
        let shouldShowSidebar: Binding<Bool> = Binding(
            /// If Sidebar is Closed, we should hide the sidebar
            get: { sidebarState == .closed },
            set: { _ in }
        )
        let shouldShowContent = Binding(
            /// If Sidebar is Closed, we should hide the sidebar
            get: { sidebarState != .closed },
            set: { _ in }
        )
        let shouldShowSidebarIconInTopBar = Binding(
            /// If Sidebar is Closed, we should hide the sidebar
            get: { sidebarState == .closed },
            set: { _ in }
        )
        
        ZStack {
            Rectangle()
                .fill(backgroundColor)
                .ignoresSafeArea()
            
                HStack(spacing: spacing) {
                    
                    sidebar()

                    VStack(spacing: 0) {
                        topbar(shouldShowSidebarIconInTopBar)
                        
                        switch appViewState {
                        case .home:
                            DownloadVMView(appViewState: $appViewState)
                        case .vm:
                            virtualMachineView()
                        }
                    }
            }
            .padding(spacing)
        }
        .task {
            vmLoader.load()
        }
        .alert(isPresented: $vmLoader.showError) {
            Alert(
                title: Text("Error"),
                message: Text(vmLoader.error ?? "Unkown Error")
            )
        }
        .navigationBarBackButtonHidden(true)
        .ignoresSafeArea(edges: .top)
        .windowTitlebarArea(
            shouldShowContent: shouldShowContent,
            shouldHideTrafficLights: shouldShowSidebar,
            content: {
                sidebarIcon()
            }
        )
    }
    
    @ViewBuilder
    private func sidebar() -> some View {
        Sidebar(
            sidebarState: $sidebarState,
            bootIntoRecovery: $vmLoader.bootIntoRecovery,
            width: 200,
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    @ViewBuilder
    private func topbar(
        _ shouldShowSidebarIconInTopBar: Binding<Bool>
    ) -> some View {
        
    TopBar(
        appViewState: $appViewState,
        shouldShowSidebarIcon: shouldShowSidebarIconInTopBar,
        height: topBarHeight
    ) {
        sidebarIcon()
    } playPauseIcon: {
        playPauseButton()
    } reloadButton: {
        reloadButton()
    }
    .clipShape(
        .rect(
            topLeadingRadius: 8,
            topTrailingRadius: 8
        )
    )
}
    
    @ViewBuilder
    private func virtualMachineView() -> some View {
        VirtualMachineView(
            vmLoader: vmLoader
        )
        .clipShape(
            .rect(
                bottomLeadingRadius: 8,
                bottomTrailingRadius: 8
            )
        )
    }
    
    @ViewBuilder
    private func sidebarIcon() -> some View {
        CustomButton(icon: "sidebar.left", action: {
            if sidebarState == .closed {
                withAnimation(.spring) {
                    sidebarState = .open
                }
            } else if sidebarState == .open {
                withAnimation(.spring) {
                    sidebarState = .closed
                }
            }
        })
    }
    
    @ViewBuilder
    private func playPauseButton() -> some View {
        CustomButton(icon: vmLoader.isPaused ? "play" : "pause", width: 10, height: 16, action: {
            if vmLoader.isPaused {
                vmLoader.playVirtualMachine()
            } else {
                vmLoader.pauseVirtualMachine()
            }
        })
    }
    
    @ViewBuilder
    private func reloadButton() -> some View {
        CustomButton(icon: "arrow.clockwise", width: 15) {
            vmLoader.reloadVirtualMachine()
        }
    }
}

#Preview {
    VMScreen()
        .padding()
        .frame(width: 600, height: 600)
}
