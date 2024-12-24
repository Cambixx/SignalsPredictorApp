import Foundation

struct PredictionGroup: Identifiable {
    let id = UUID()
    let title: String
    let predictions: [PredictionSignal]
    let isSpeculative: Bool
} 