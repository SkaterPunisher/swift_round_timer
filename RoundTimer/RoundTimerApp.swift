import SwiftUI
import BackgroundTasks

@main
struct RoundTimerApp: App {
    
    init() {
        // Регистрируем background app refresh
        registerBackgroundTasks()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .backgroundTask(.appRefresh("timer-refresh")) {
            // Обработка background app refresh
            await handleBackgroundRefresh()
        }
    }
    
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "timer-refresh", using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }
    
    private func handleAppRefresh(task: BGAppRefreshTask) {
        // Планируем следующий background refresh
        scheduleAppRefresh()
        
        task.setTaskCompleted(success: true)
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