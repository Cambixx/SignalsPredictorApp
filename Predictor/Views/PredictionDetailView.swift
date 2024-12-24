import SwiftUI

struct PredictionDetailView: View {
    let prediction: PredictionSignal
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var backgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : .white
    }
    
    var body: some View {
        ZStack {
            // Fondo semitransparente
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                    }
                }
            
            // Contenido del modal
            VStack(alignment: .leading, spacing: 16) {
                // Cabecera
                HStack {
                    Text(prediction.pair)
                        .font(.title2)
                        .bold()
                    Spacer()
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isPresented = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                
                // Precios y confianza
                VStack(spacing: 12) {
                    HStack {
                        PriceDetailView(label: "Precio actual", value: prediction.currentPrice)
                        Spacer()
                        PriceDetailView(label: "Objetivo", value: prediction.predictedPrice)
                    }
                    
                    HStack {
                        Text("Ganancia potencial:")
                            .foregroundColor(.secondary)
                        Text(prediction.potentialGain)
                            .foregroundColor(.green)
                            .bold()
                        Spacer()
                        Text("Confianza: \(prediction.confidence)%")
                            .foregroundColor(prediction.confidenceColor)
                            .bold()
                    }
                }
                .padding(.vertical, 8)
                
                Divider()
                
                // Análisis detallado
                VStack(alignment: .leading, spacing: 12) {
                    Text("Análisis Detallado")
                        .font(.headline)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(prediction.analysis.components(separatedBy: ". "), id: \.self) { point in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 6))
                                        .foregroundColor(.orange)
                                        .padding(.top, 6)
                                    Text(point)
                                        .foregroundColor(.primary.opacity(0.9))
                                }
                            }
                        }
                    }
                }
                
                Divider()
                
                // Información adicional
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Timeframe")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(prediction.timeframe)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Actualizado")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(prediction.formattedTimestamp)
                    }
                }
            }
            .padding()
            .background(backgroundColor)
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding()
        }
        .transition(.opacity.combined(with: .scale))
    }
}

struct PriceDetailView: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3.monospaced())
                .bold()
        }
    }
} 