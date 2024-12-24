import SwiftUI

struct LoaderView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var isAnimating = false
    
    var backgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.7) : Color.white.opacity(0.9)
    }
    
    var textColor: Color {
        colorScheme == .dark ? .white : .primary
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Circle()
                    .stroke(lineWidth: 8)
                    .frame(width: 80, height: 80)
                    .foregroundColor(.orange)
                    .overlay(
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(textColor, lineWidth: 8)
                            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                            .animation(
                                Animation.linear(duration: 1)
                                    .repeatForever(autoreverses: false),
                                value: isAnimating
                            )
                    )
                
                Text("Analizando mercado...")
                    .font(.headline)
                    .foregroundColor(textColor)
                    .shadow(radius: 1)
            }
            .padding(40)
            .background(backgroundColor)
            .cornerRadius(20)
        }
        .onAppear {
            isAnimating = true
        }
    }
} 