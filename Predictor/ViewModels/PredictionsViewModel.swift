import Foundation

@MainActor
class PredictionsViewModel: ObservableObject {
    @Published var predictionGroups: [PredictionGroup] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let fixedPairs = ["BTCUSDT", "DOGEUSDT", "PEPEUSDT"]
    private let analyzer: SignalAnalyzer
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
                await fetchPredictions()
                try? await Task.sleep(nanoseconds: 15 * 60 * 1_000_000_000) // 15 minutos
            }
        }
    }
    
    func fetchPredictions() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            var allPredictions: [PredictionSignal] = []
            
            // 1. Primero obtenemos predicciones para los pares fijos
            print("📊 Analizando pares fijos...")
            for pair in fixedPairs {
                print("🔍 Analizando \(pair)...")
                if let prediction = try await analyzer.analyzeSpeculativePrediction(pair) {
                    allPredictions.append(prediction)
                }
            }
            
            // 2. Luego obtenemos los mejores 5 pares adicionales (excluyendo los fijos)
            let topVolumePairs = try await analyzer.getTopVolumeSymbols(count: 50, excludingSymbols: fixedPairs)
            print("📊 Analizando pares adicionales...")
            
            var additionalPredictions: [PredictionSignal] = []
            for symbol in topVolumePairs {
                print("🔍 Analizando \(symbol)...")
                if let prediction = try await analyzer.analyzeSpeculativePrediction(symbol) {
                    additionalPredictions.append(prediction)
                }
            }
            
            // Ordenar predicciones adicionales por confianza y tomar las 5 mejores
            let top5Additional = additionalPredictions
                .sorted { $0.confidence > $1.confidence }
                .prefix(5)
            
            // Combinar todas las predicciones
            allPredictions.append(contentsOf: top5Additional)
            
            // Crear grupo de predicciones
            if !allPredictions.isEmpty {
                predictionGroups = [
                    PredictionGroup(
                        title: "Predicciones",
                        predictions: allPredictions,
                        isSpeculative: true
                    )
                ]
            } else {
                predictionGroups = []
            }
            
            print("🎲 Total predicciones: \(allPredictions.count) (Fijas: \(allPredictions.count - top5Additional.count), Adicionales: \(top5Additional.count))")
            
        } catch {
            print("❌ Error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
} 