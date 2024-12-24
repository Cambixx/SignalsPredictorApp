import SwiftUI

struct MarketView: View {
    @StateObject private var viewModel = MarketViewModel()
    
    var body: some View {
        ZStack {
            if viewModel.cryptoPairs.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    Text("Cargando datos del mercado...")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 10)
            } else {
                ScrollView {
                    LazyVStack(spacing: 15) {
                        ForEach(viewModel.cryptoPairs, id: \.symbol) { pair in
                            CryptoPairCard(pair: pair)
                                .padding(.horizontal)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }
                    }
                    .padding(.vertical)
                }
            }
            
            if viewModel.isLoading {
                Color.black.opacity(0.1)
                    .ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
        .navigationTitle("Mercado")
        .refreshable {
            await viewModel.fetchMarketData()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .task {
            if viewModel.cryptoPairs.isEmpty {
                await viewModel.fetchMarketData()
            }
        }
    }
}

struct CryptoPairCard: View {
    let pair: CryptoPair
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(pair.symbol)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(pair.price)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                PriceChangeView(priceChange: pair.priceChange)
            }
            .padding()
            
            Divider()
            
            HStack {
                Text("24h Vol:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(pair.volume)
                    .font(.caption)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    // Aquí irá la acción para ver más detalles
                }) {
                    Text("Ver más")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct PriceChangeView: View {
    let priceChange: String
    
    private var isPositive: Bool {
        !priceChange.hasPrefix("-")
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
            Text(priceChange)
        }
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundColor(isPositive ? .green : .red)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            (isPositive ? Color.green : Color.red)
                .opacity(0.1)
        )
        .cornerRadius(8)
    }
}

#Preview {
    NavigationStack {
        MarketView()
    }
} 