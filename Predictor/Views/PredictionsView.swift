import SwiftUI

struct PredictionsView: View {
    @StateObject private var viewModel = PredictionsViewModel()
    @State private var selectedPrediction: PredictionSignal? // Para controlar qué predicción mostrar
    
    var body: some View {
        ZStack {
            if viewModel.predictionGroups.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    Text("No hay predicciones disponibles")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 10)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(viewModel.predictionGroups) { group in
                            PredictionGroupView(group: group, onPredictionTap: { prediction in
                                selectedPrediction = prediction
                            })
                        }
                    }
                    .padding()
                }
            }
            
            if viewModel.isLoading {
                LoaderView()
            }
            
            // Modal sobre todo el contenido
            if let prediction = selectedPrediction {
                PredictionDetailView(
                    prediction: prediction,
                    isPresented: Binding(
                        get: { selectedPrediction != nil },
                        set: { if !$0 { selectedPrediction = nil } }
                    )
                )
                .transition(.opacity.combined(with: .scale))
            }
        }
        .navigationTitle("Predicciones")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await viewModel.fetchPredictions()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .task {
            await viewModel.fetchPredictions()
        }
    }
}

struct PredictionGroupView: View {
    @Environment(\.colorScheme) var colorScheme
    let group: PredictionGroup
    let onPredictionTap: (PredictionSignal) -> Void
    
    var shadowColor: Color {
        if colorScheme == .dark {
            return group.isSpeculative ? Color.orange.opacity(0.3) : Color.blue.opacity(0.3)
        } else {
            return group.isSpeculative ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(group.title)
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal)
            
            ForEach(group.predictions) { prediction in
                PredictionRowView(
                    prediction: prediction,
                    onTap: { onPredictionTap(prediction) }
                )
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: shadowColor, radius: 5, x: 0, y: 2)
            }
        }
        .padding(.vertical, 8)
    }
}

struct PredictionRowView: View {
    @Environment(\.colorScheme) var colorScheme
    let prediction: PredictionSignal
    let onTap: () -> Void
    
    var backgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : .white
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(prediction.pair)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(prediction.confidence)%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(prediction.confidenceColor)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Precio actual:")
                            .font(.subheadline)
                            .foregroundColor(.primary.opacity(0.8))
                        Text(prediction.currentPrice)
                            .font(.subheadline.monospaced())
                            .foregroundColor(.primary)
                    }
                    
                    HStack {
                        Text("Objetivo:")
                            .font(.subheadline)
                            .foregroundColor(.primary.opacity(0.8))
                        Text(prediction.predictedPrice)
                            .font(.subheadline.monospaced())
                            .foregroundColor(.primary)
                        Text("(\(prediction.potentialGain))")
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                    }
                }
                
                Text(prediction.analysis.components(separatedBy: ". ").prefix(2).joined(separator: ". "))
                    .font(.caption)
                    .foregroundColor(.primary.opacity(0.7))
                    .lineLimit(2)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(backgroundColor)
        }
    }
}