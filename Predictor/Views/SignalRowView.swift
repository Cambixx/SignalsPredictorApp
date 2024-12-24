import SwiftUI

struct SignalRowView: View {
    @Environment(\.colorScheme) var colorScheme
    let signal: TradingSignal
    
    var backgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : .white
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(signal.pair)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(signal.confidence)%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(signal.confidenceColor)
            }
            
            HStack {
                Text(signal.type.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(signal.type == .buy ? Color.green.opacity(0.8) : Color.red.opacity(0.8))
                    .cornerRadius(4)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Text("Entrada:")
                            .font(.subheadline)
                            .foregroundColor(.primary.opacity(0.8))
                        Text(signal.entryPrice)
                            .font(.subheadline.monospaced())
                            .foregroundColor(.primary)
                    }
                    
                    HStack {
                        Text("Objetivo:")
                            .font(.subheadline)
                            .foregroundColor(.primary.opacity(0.8))
                        Text(signal.targetPrice)
                            .font(.subheadline.monospaced())
                            .foregroundColor(.primary)
                    }
                }
            }
            
            Text(signal.formattedTimestamp)
                .font(.caption2)
                .foregroundColor(.primary.opacity(0.6))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(backgroundColor)
        .cornerRadius(12)
    }
}

struct PriceView: View {
    let label: String
    let price: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(price)
                .font(.caption.monospaced())
                .fontWeight(.medium)
        }
    }
}

#Preview {
    List {
        SignalRowView(signal: TradingSignal(
            pair: "PEPE/USDT",
            type: .buy,
            entryPrice: "0.00002091",
            targetPrice: "0.00002150",
            timestamp: Date(),
            confidence: 85
        ))
        
        SignalRowView(signal: TradingSignal(
            pair: "BTC/USDT",
            type: .sell,
            entryPrice: "50000.00",
            targetPrice: "51000.00",
            timestamp: Date(),
            confidence: 75
        ))
    }
} 