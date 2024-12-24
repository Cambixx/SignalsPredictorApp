import SwiftUI

struct TradingSignal: Identifiable {
    let id: UUID = UUID()
    let pair: String
    let type: SignalType
    let entryPrice: String
    let targetPrice: String
    let timestamp: Date
    let confidence: Int // 0-100
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    var confidenceColor: Color {
        switch confidence {
        case 0..<40: return .red
        case 40..<70: return .yellow
        default: return .green
        }
    }
}

enum SignalType: String {
    case buy = "COMPRAR"
    case sell = "VENDER"
} 