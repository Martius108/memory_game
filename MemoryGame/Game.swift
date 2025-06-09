//
//  Game.swift
//  MemoryGame
//
//  Created by Martin Lanius on 07.06.25.
//

import SwiftUI

struct Card: Identifiable {
    let id = UUID()
    let image: UIImage
    var isFlipped: Bool = false
    var isMatched: Bool = false
}

struct GameView: View {
    @State private var cards: [Card]
    @State private var startTime = Date()
    @State private var endTime: Date?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @AppStorage("bestTime") private var bestTime: Double?
    @Environment(\.dismiss) private var dismiss

    let backImage: UIImage = {
        let original = UIImage(named: "Back")!
        let size = min(original.size.width, original.size.height)
        let rect = CGRect(x: (original.size.width - size) / 2,
                          y: (original.size.height - size) / 2,
                          width: size,
                          height: size)
        if let cgImage = original.cgImage?.cropping(to: rect) {
            return UIImage(cgImage: cgImage)
        }
        return original
    }()

    init(images: [UIImage]) {
        let limit = UIDevice.current.userInterfaceIdiom == .pad ? 12 : 4
        let uniqueImages = Array(Set(images.map { $0.pngData() ?? Data() })).prefix(limit).compactMap { data in
            UIImage(data: data)
        }
        let selected = Array(uniqueImages)
        let paired = selected + selected
        _cards = State(initialValue: paired.shuffled().map { Card(image: $0) })
    }

    var body: some View {
        VStack {

            let columnCount = UIDevice.current.userInterfaceIdiom == .pad ? 4 : 2
            let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: columnCount)
            ScrollView([.horizontal, .vertical]) {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(cards) { card in
                        let index = cards.firstIndex(where: { $0.id == card.id })!
                        ZStack {
                            if card.isFlipped || card.isMatched {
                                Image(uiImage: card.image)
                                    .resizable()
                                    .scaledToFit()
                            } else {
                                Image(uiImage: backImage)
                                    .resizable()
                                    .scaledToFit()
                            }
                        }
                        .frame(width: 160, height: 160)
                        .border(.blue)
                        .onTapGesture {
                            flipCard(at: index)
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            startTime = Date()
        }
        .navigationTitle("Memory Game")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(NSLocalizedString("GameOverTitle", comment: "")),
                message: Text(alertMessage),
                primaryButton: .cancel(Text("No")) {
                    dismiss()
                },
                secondaryButton: .default(Text("Yes")) {
                    restartGame()
                }
            )
        }
    }

    func flipCard(at index: Int) {
        guard !cards[index].isFlipped, !cards[index].isMatched else { return }
        cards[index].isFlipped = true

        let flippedIndices = cards.indices.filter { cards[$0].isFlipped && !cards[$0].isMatched }
        if flippedIndices.count == 2 {
            let first = flippedIndices[0]
            let second = flippedIndices[1]
            if cards[first].image.pngData() == cards[second].image.pngData() {
                cards[first].isMatched = true
                cards[second].isMatched = true
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    cards[first].isFlipped = false
                    cards[second].isFlipped = false
                }
            }
        }
        if cards.allSatisfy({ $0.isMatched }) {
            endTime = Date()
            if let endTime = endTime {
                let duration = endTime.timeIntervalSince(startTime)
                if bestTime == nil || duration < bestTime! {
                    bestTime = duration
                }
                let timeValue = formattedTime(duration)
                let bestValue = formattedTime(bestTime ?? duration)
                alertMessage = String(
                    format: NSLocalizedString("TimeAndBestTime", comment: ""),
                    timeValue,
                    bestValue
                ) + "\n" + NSLocalizedString("PlayAgain", comment: "")
            } else {
                alertMessage = "Game over."
            }
            showAlert = true
        }
    }

    func restartGame() {
        let limit = UIDevice.current.userInterfaceIdiom == .pad ? 12 : 4
        var seenHashes = Set<Int>()
        let uniqueImages = cards.map { $0.image }.filter {
            guard let data = $0.pngData() else { return false }
            let hash = data.hashValue
            return seenHashes.insert(hash).inserted
        }.prefix(limit)

        let selected = Array(uniqueImages)
        let paired = selected + selected
        cards = paired.shuffled().map { Card(image: $0) }
        startTime = Date()
        endTime = nil
    }
    
    func formattedTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
