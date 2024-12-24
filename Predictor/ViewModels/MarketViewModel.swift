import Foundation

@MainActor
class MarketViewModel: ObservableObject {
    @Published var cryptoPairs: [CryptoPair] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let binanceService = BinanceService()
    private let supportedPairs = ["BTCUSDT", "ETHUSDT", "BNBUSDT", "ADAUSDT", "DOGEUSDT"]
    
    func fetchMarketData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            var updatedPairs: [CryptoPair] = []
            var errors: [String] = []
            
            for symbol in supportedPairs {
                do {
                    let ticker = try await binanceService.fetchTicker(symbol: symbol)
                    let pair = createCryptoPair(from: ticker)
                    updatedPairs.append(pair)
                    
                    // Añadimos un pequeño retraso entre peticiones
                    if symbol != supportedPairs.last {
                        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 segundos
                    }
                } catch {
                    let errorMessage = "\(symbol): \(error.localizedDescription)"
                    print("Error fetching \(errorMessage)")
                    errors.append(errorMessage)
                    continue
                }
            }
            
            if updatedPairs.isEmpty {
                if errors.isEmpty {
                    throw NetworkError.networkError(NSError(domain: "", code: -1, 
                        userInfo: [NSLocalizedDescriptionKey: "No se pudo obtener información de ningún par"]))
                } else {
                    throw NetworkError.networkError(NSError(domain: "", code: -1, 
                        userInfo: [NSLocalizedDescriptionKey: "Errores: \(errors.joined(separator: "\n"))"]))
                }
            }
            
            cryptoPairs = updatedPairs
        } catch {
            if let networkError = error as? NetworkError {
                errorMessage = networkError.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
    }
    
    private func createCryptoPair(from ticker: TickerResponse) -> CryptoPair {
        CryptoPair(
            symbol: formatSymbol(ticker.symbol),
            price: formatPrice(ticker.lastPrice),
            priceChange: formatPriceChange(ticker.priceChangePercent),
            volume: formatVolume(ticker.volume, quoteVolume: ticker.quoteVolume)
        )
    }
    
    private func formatPriceChange(_ change: String) -> String {
        if let value = Double(change) {
            return String(format: "%.2f%%", value)
        }
        return change + "%"
    }
    
    private func formatPrice(_ price: String) -> String {
        guard let value = Double(price) else { return price }
        return String(format: "%.2f", value)
    }
    
    private func formatSymbol(_ symbol: String) -> String {
        // Convierte BTCUSDT a BTC/USDT
        let base = symbol.dropLast(4)
        let quote = symbol.suffix(4)
        return "\(base)/\(quote)"
    }
    
    private func formatVolume(_ volume: String, quoteVolume: String) -> String {
        if let value = Double(quoteVolume) {
            if value >= 1_000_000_000 {
                return String(format: "$%.1fB", value / 1_000_000_000)
            } else if value >= 1_000_000 {
                return String(format: "$%.1fM", value / 1_000_000)
            } else if value >= 1_000 {
                return String(format: "$%.1fK", value / 1_000)
            }
            return String(format: "$%.2f", value)
        }
        return quoteVolume
    }
} 