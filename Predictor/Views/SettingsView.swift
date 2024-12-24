import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        List {
            Section(header: Text("Apariencia")) {
                Toggle(isOn: $viewModel.isDarkMode) {
                    Label {
                        Text("Modo Oscuro")
                    } icon: {
                        Image(systemName: viewModel.isDarkMode ? "moon.fill" : "sun.max.fill")
                    }
                }
            }
            
            Section(header: Text("Información")) {
                HStack {
                    Label("Versión", systemImage: "info.circle")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Ajustes")
    }
} 