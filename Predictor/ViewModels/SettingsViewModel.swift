import SwiftUI

class SettingsViewModel: ObservableObject {
    @AppStorage("isDarkMode") var isDarkMode: Bool = true
    
    // Podemos añadir más configuraciones aquí en el futuro
} 