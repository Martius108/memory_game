//
//  ImagePicker.swift
//  MemoryGame
//
//  Created by Martin Lanius on 07.06.25.
//

import SwiftUI
import PhotosUI

struct ImagePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var showPhotosPicker = false
    var onImagePicked: (UIImage) -> Void

    var body: some View {
        EmptyView()
            .photosPicker(isPresented: $showPhotosPicker, selection: $selectedItem, matching: .images, photoLibrary: .shared())
            .onAppear {
                // Beim Erscheinen des Views wird der PhotosPicker automatisch präsentiert.
                showPhotosPicker = true
            }
            .task(id: selectedItem) {
                guard let item = selectedItem else { return }
                do {
                    if let data = try await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data),
                       image.size.width > 0, image.size.height > 0 {
                        onImagePicked(image)
                        dismiss()
                    } else {
                        print("Image could not be loaded.")
                    }
                } catch {
                    print("Error while loading image: \(error.localizedDescription)")
                }
            }
    }
}
