import SwiftUI

struct SignalsView: View {
    @StateObject private var viewModel = SignalsViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    var emptyStateBackgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : .white
    }
    
    var body: some View {
        ZStack {
            if viewModel.tradingSignals.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                    Text("No hay señales disponibles")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(emptyStateBackgroundColor)
                .cornerRadius(12)
                .shadow(radius: 10)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.tradingSignals) { signal in
                            SignalRowView(signal: signal)
                                .shadow(color: colorScheme == .dark ? 
                                    Color.blue.opacity(0.3) : Color.blue.opacity(0.2),
                                    radius: 5, x: 0, y: 2)
                        }
                    }
                    .padding()
                }
            }
            
            if viewModel.isLoading {
                LoaderView()
            }
        }
        .navigationTitle("Señales")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await viewModel.fetchSignals()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .overlay {
            if let error = viewModel.errorMessage {
                VStack {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.1)))
                        .padding()
                    Spacer()
                }
            }
        }
        .task {
            if viewModel.tradingSignals.isEmpty {
                await viewModel.fetchSignals()
            }
        }
    }
}

struct SignalCard: View {
    let signal: TradingSignal
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(signal.pair)
                        .font(.headline)
                    Text(signal.type.rawValue)
                        .font(.subheadline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(signal.type == .buy ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                        .cornerRadius(8)
                }
                Spacer()
                Text("\(signal.confidence)%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(signal.confidenceColor)
            }
            .padding()
            
            Divider()
            
            VStack(spacing: 8) {
                HStack {
                    PriceInfoView(title: "Entrada", value: signal.entryPrice)
                    Spacer()
                    PriceInfoView(title: "Objetivo", value: signal.targetPrice)
                }
                
                HStack {
                    Text(signal.formattedTimestamp)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct PriceInfoView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    NavigationStack {
        SignalsView()
    }
} 