import Foundation

@MainActor
class SignalsViewModel: ObservableObject {
    @Published var tradingSignals: [TradingSignal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdate: Date?
    
    private let analyzer: SignalAnalyzer
    private var supportedPairs: [String] = ["BTCUSDT", "DOGEUSDT", "PEPEUSDT"]
    private var backgroundTask: Task<Void, Never>?
    
    init(analyzer: SignalAnalyzer = SignalAnalyzer()) {
        self.analyzer = analyzer
        setupBackgroundFetch()
    }
    
    deinit {
        backgroundTask?.cancel()
    }
    
    private func setupBackgroundFetch() {
        backgroundTask = Task {
            while !Task.isCancelled {
                await fetchSignals()
                try? await Task.sleep(nanoseconds: 15 * 60 * 1_000_000_000) // 15 minutos
            }
        }
    }
    
    func fetchSignals() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            let topVolumePairs = try await analyzer.getTopVolumeSymbols(
                count: 5,
                excludingSymbols: ["BTCUSDT", "DOGEUSDT", "PEPEUSDT"]
            )
            
            supportedPairs = ["BTCUSDT", "DOGEUSDT", "PEPEUSDT"] + topVolumePairs
            
            var newSignals: [TradingSignal] = []
            var errors: [String] = []
            
            for symbol in supportedPairs {
                do {
                    if let signal = try await analyzer.analyzeSymbol(symbol) {
                        newSignals.append(signal)
                        if !tradingSignals.contains(where: { $0.id == signal.id }) {
                            await NotificationManager.shared.scheduleNotification(for: signal)
                        }
                    }
                    
                    if symbol != supportedPairs.last {
                        try await Task.sleep(nanoseconds: 500_000_000)
                    }
                } catch {
                    let errorMessage = "\(symbol): \(error.localizedDescription)"
                    print("Error analyzing \(errorMessage)")
                    errors.append(errorMessage)
                }
            }
            
            if newSignals.isEmpty && !errors.isEmpty {
                throw NetworkError.networkError(NSError(domain: "", code: -1, 
                    userInfo: [NSLocalizedDescriptionKey: "Errores: \(errors.joined(separator: "\n"))"]))
            }
            
            tradingSignals = newSignals.sorted { 
                if $0.confidence == $1.confidence {
                    return $0.timestamp > $1.timestamp
                }
                return $0.confidence > $1.confidence
            }
            
            lastUpdate = Date()
        } catch {
            if let networkError = error as? NetworkError {
                errorMessage = networkError.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
    }
} 