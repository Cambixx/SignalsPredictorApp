import Foundation

struct Kline {
    let openTime: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
    let closeTime: Date
    let quoteVolume: Double
    let trades: Int
    let takerBuyBaseVolume: Double
    let takerBuyQuoteVolume: Double
    
    init(rawData: [Any]) {
        self.openTime = Date(timeIntervalSince1970: (rawData[0] as? Double ?? 0) / 1000)
        self.open = Double(rawData[1] as? String ?? "0") ?? 0
        self.high = Double(rawData[2] as? String ?? "0") ?? 0
        self.low = Double(rawData[3] as? String ?? "0") ?? 0
        self.close = Double(rawData[4] as? String ?? "0") ?? 0
        self.volume = Double(rawData[5] as? String ?? "0") ?? 0
        self.closeTime = Date(timeIntervalSince1970: (rawData[6] as? Double ?? 0) / 1000)
        self.quoteVolume = Double(rawData[7] as? String ?? "0") ?? 0
        self.trades = rawData[8] as? Int ?? 0
        self.takerBuyBaseVolume = Double(rawData[9] as? String ?? "0") ?? 0
        self.takerBuyQuoteVolume = Double(rawData[10] as? String ?? "0") ?? 0
    }
} 