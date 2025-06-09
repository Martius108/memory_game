//
//  ContentView.swift
//  MemoryGame
//
//  Created by Martin Lanius on 07.06.25.
//


import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ContentView: View {
    @AppStorage("savedImages") private var savedImagesData: Data = Data()
    @State private var selectedImage: UIImage?
    @State private var croppedImages: [UIImage] = [] {
        didSet {
            savedImagesData = try! JSONEncoder().encode(croppedImages.compactMap { $0.pngData() })
        }
    }
    @State private var showImagePicker = false
    @State private var gameStarted = false
    struct IdentifiableImage: Identifiable {
        let id = UUID()
        let image: UIImage
    }
    @State private var pendingImage: IdentifiableImage?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    init() {
        if let imagesData = try? JSONDecoder().decode([Data].self, from: UserDefaults.standard.data(forKey: "savedImages") ?? Data()) {
            _croppedImages = State(initialValue: imagesData.compactMap { UIImage(data: $0) })
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                if croppedImages.isEmpty {
                    Image("Icon")
                        .resizable()
                        .frame(width: 100, height: 100)
                    Text("Please choose some images for your Memory Game")
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 50)
                }
                Button("Choose Image") {
                    showImagePicker = true
                }
                .padding(.top, 50)
                Spacer()
                if croppedImages.count >= 2 {
                    Button("Start Game") {
                        gameStarted = true
                    }
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .padding(.top)
                }

                if !croppedImages.isEmpty {
                    let columnCount = horizontalSizeClass == .compact ? 2 : 4
                    let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: columnCount)
                    ScrollView([.horizontal, .vertical]) {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(croppedImages.indices, id: \.self) { index in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: croppedImages[index])
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                        .border(.gray)
                                    Button(action: {
                                        croppedImages.remove(at: index)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                            .padding(4)
                                    }
                                }
                            }
                        }
                        .padding()
                    }

                    Button("Delete all images") {
                        croppedImages.removeAll()
                        savedImagesData = Data()
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 6)
                    .foregroundColor(.red)
                }
                Spacer()
            }
            .padding()
            .sheet(isPresented: $showImagePicker) {
                ImagePickerSheet(onImagePicked: { image in
                    pendingImage = IdentifiableImage(image: image)
                })
            }
            .fullScreenCover(item: $pendingImage) { identifiable in
                CropView(image: identifiable.image) { cropped in
                    croppedImages.append(cropped)
                    // Spielstart nicht automatisch
                }
            }
            .navigationDestination(isPresented: $gameStarted) {
                GameView(images: croppedImages.shuffled())
            }
        }
    }

    func cropImageToSquare(image: UIImage, size: CGFloat) -> UIImage {
        let cgImage = image.cgImage!
        let minLength = min(cgImage.width, cgImage.height)
        let cropRect = CGRect(x: (cgImage.width - minLength) / 2,
                              y: (cgImage.height - minLength) / 2,
                              width: minLength,
                              height: minLength)
        if let cropped = cgImage.cropping(to: cropRect) {
            let uiImage = UIImage(cgImage: cropped)
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
            return renderer.image { _ in
                uiImage.draw(in: CGRect(origin: .zero, size: CGSize(width: size, height: size)))
            }
        }
        return image
    }

    func gridCardCount() -> Int {
        if horizontalSizeClass == .compact {
            return 8 // iPhone
        } else {
            return 16 // iPad
        }
    }
}

#Preview {
    ContentView()
}
