//
//  CropView.swift
//  MemoryGame
//
//  Created by Martin Lanius on 07.06.25.
//

import SwiftUI

struct CropView: View {
    let image: UIImage
    var onCrop: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var offset = CGSize.zero
    @State private var scale: CGFloat = 1.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(DragGesture().onChanged { value in
                        offset = value.translation
                    })
                    .gesture(MagnificationGesture().onChanged { value in
                        scale = value
                    })

                Rectangle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 300, height: 300)
            }

            VStack {
                Spacer()
                Button("Choose frame") {
                    let renderer = ImageRenderer(content:
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(scale)
                            .offset(offset)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    )
                    if let uiImage = renderer.uiImage {
                        let cropped = cropCenterSquare(from: uiImage, size: 160)
                        onCrop(cropped)
                    }
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding()
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .padding(.leading, 70)
                .padding(.trailing, 70)
                .padding(.bottom, 60)
            }
        }
    }

    func cropCenterSquare(from image: UIImage, size: CGFloat) -> UIImage {
        let cgImage = image.cgImage!
        let cropRect = CGRect(x: (cgImage.width - Int(size)) / 2,
                              y: (cgImage.height - Int(size)) / 2,
                              width: Int(size), height: Int(size))
        if let cropped = cgImage.cropping(to: cropRect) {
            return UIImage(cgImage: cropped)
        }
        return image
    }
}
