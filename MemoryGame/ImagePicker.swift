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
    @State private var isLoading = false
    var onImagePicked: (UIImage) -> Void

    var body: some View {
        ZStack {
            Color.clear
                .frame(width: 1, height: 1)
                .photosPicker(isPresented: $showPhotosPicker, selection: $selectedItem, matching: .images, photoLibrary: .shared())

            if isLoading {
                ProgressView("Loading image ...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
                    .background(Color(.systemBackground).opacity(0.8))
                    .cornerRadius(10)
            }
        }
        .onAppear {
            showPhotosPicker = true
        }
        .task(id: selectedItem) {
            guard let item = selectedItem else { return }
            isLoading = true
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
            isLoading = false
        }
    }
}
