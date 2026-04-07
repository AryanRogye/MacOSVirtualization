//
//  URLPicker.swift
//  MacOSVirtualization
//
//  Created by Aryan Rogye on 4/7/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct URLPicker: View {
    @Binding var selectedURL: URL?
    @State private var isImporterPresented = false

    var title: String = "Select a file or folder"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Button("Choose…") {
                    isImporterPresented = true
                }
                if let url = selectedURL {
                    Text(url.path)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No selection")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.item], // allows files and folders
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let first = urls.first {
                    selectedURL = first
                }
            case .failure:
                break
            }
        }
    }
}
