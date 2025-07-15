import SwiftUI
import BackgroundTasks

@main
struct RoundTimerApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .backgroundTask(.appRefresh("timer-refresh")) {
            // Обработка background app refresh
            await handleBackgroundRefresh()
        }
    }
    
    private func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "timer-refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 минут
        
        try? BGTaskScheduler.shared.submit(request)
    }
    
    @MainActor
    private func handleBackgroundRefresh() async {
        // Обновляем приложение в фоне
        scheduleAppRefresh()
    }
} 