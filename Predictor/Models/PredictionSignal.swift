import SwiftUI

struct PredictionSignal: Identifiable {
    let id = UUID()
    let pair: String
    let currentPrice: String
    let predictedPrice: String
    let confidence: Int // 0-100
    let timeframe: String
    let analysis: String
    let timestamp = Date()
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    var potentialGain: String {
        guard let current = Double(currentPrice.replacingOccurrences(of: ",", with: "")),
              let predicted = Double(predictedPrice.replacingOccurrences(of: ",", with: "")) else {
            return "N/A"
        }
        let percentage = ((predicted - current) / current) * 100
        return String(format: "%.1f%%", percentage)
    }
    
    var confidenceColor: Color {
        switch confidence {
        case 0..<50: return .red
        case 50..<75: return .yellow
        default: return .green
        }
    }
} 