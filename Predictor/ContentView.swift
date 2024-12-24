//
//  ContentView.swift
//  Predictor
//
//  Created by Carlos Rábago on 5/12/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var signalsViewModel = SignalsViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    
    var body: some View {
        TabView {
            NavigationStack {
                SignalsView()
            }
            .tabItem {
                Label("Señales", systemImage: "bell.fill")
            }
            
            NavigationStack {
                PredictionsView()
            }
            .tabItem {
                Label("Predicciones", systemImage: "chart.xyaxis.line")
            }
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Ajustes", systemImage: "gear")
            }
        }
        .preferredColorScheme(settingsViewModel.isDarkMode ? .dark : .light)
        .task {
            do {
                try await NotificationManager.shared.requestAuthorization()
            } catch {
                print("Error requesting notification authorization:", error)
            }
        }
    }
}

#Preview {
    ContentView()
}
