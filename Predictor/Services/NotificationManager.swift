import UserNotifications
import Foundation

class NotificationManager {
    static let shared = NotificationManager()
    private var lastNotifiedSignals: Set<String> = [] // Para evitar notificaciones duplicadas
    
    private init() {}
    
    func requestAuthorization() async throws {
        let center = UNUserNotificationCenter.current()
        try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }
    
    func scheduleNotification(for signal: TradingSignal) async {
        // Solo notificamos señales con confianza muy alta (>80) o señales fuertes (>70) que sean de compra
        let shouldNotify = signal.confidence > 80 || (signal.confidence > 70 && signal.type == .buy)
        let signalKey = "\(signal.pair)-\(signal.type)-\(signal.entryPrice)"
        
        guard shouldNotify && !lastNotifiedSignals.contains(signalKey) else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "¡Señal Fuerte de Trading! 🚨"
        content.subtitle = "\(signal.pair) - \(signal.type.rawValue)"
        content.body = """
            💰 Precio entrada: \(signal.entryPrice)
            🎯 Objetivo: \(signal.targetPrice)
            📊 Confianza: \(signal.confidence)%
            """
        content.sound = .default
        
        // Añadir categoría para acciones rápidas si lo deseas
        content.categoryIdentifier = "TRADING_SIGNAL"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            lastNotifiedSignals.insert(signalKey)
            
            // Limpiamos señales antiguas después de 4 horas
            DispatchQueue.main.asyncAfter(deadline: .now() + 14400) { [weak self] in
                self?.lastNotifiedSignals.remove(signalKey)
            }
        } catch {
            print("Error scheduling notification:", error)
        }
    }
    
    // Opcional: Añadir acciones rápidas a las notificaciones
    func setupNotificationActions() {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION",
            title: "Ver Detalles",
            options: .foreground
        )
        
        let category = UNNotificationCategory(
            identifier: "TRADING_SIGNAL",
            actions: [viewAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
} 