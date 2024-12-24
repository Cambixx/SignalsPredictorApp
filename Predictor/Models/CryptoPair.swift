import SwiftUI

struct CryptoPair {
    let symbol: String
    let price: String
    let priceChange: String
    let volume: String
    
    var priceChangeColor: Color {
        if priceChange.hasPrefix("-") {
            return .red
        }
        return .green
    }
    
    var priceChangeValue: Double {
        if let value = Double(priceChange.replacingOccurrences(of: "%", with: "")) {
            return value
        }
        return 0
    }
} 