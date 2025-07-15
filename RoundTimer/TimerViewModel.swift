import Foundation
import AVFoundation
import Combine
import AudioToolbox

enum TimerState {
    case stopped
    case work
    case rest
    case paused
}

class TimerViewModel: ObservableObject {
    @Published var currentTime: Int = 0
    @Published var workTime: Int = 180 // 3 минуты по умолчанию
    @Published var restTime: Int = 60 // 1 минута по умолчанию
    @Published var currentRound: Int = 1
    @Published var totalRounds: Int = 5
    @Published var timerState: TimerState = .stopped
    @Published var isRunning: Bool = false
    
    private var timer: Timer?
    private var audioPlayer: AVAudioPlayer?
    
    // Date-based timer properties
    private var phaseStartTime: Date?
    private var currentPhaseDuration: Int = 0
    private var pausedTimeRemaining: Int = 0
    private var backgroundTime: Date?
    
    init() {
        setupAudio()
        setupNotifications()
        reset()
    }
    
    private func setupAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Ошибка настройки аудио: \(error)")
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.handleAppWillResignActive()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.handleAppDidBecomeActive()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func startTimer() {
        if timerState == .stopped {
            timerState = .work
            currentTime = workTime
            currentPhaseDuration = workTime
        }
        
        isRunning = true
        phaseStartTime = Date()
        pausedTimeRemaining = 0
        
        startUITimer()
    }
    
    func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        timerState = .paused
        
        // Сохраняем оставшееся время
        if let startTime = phaseStartTime {
            let elapsed = Int(Date().timeIntervalSince(startTime))
            pausedTimeRemaining = max(0, currentPhaseDuration - elapsed)
        } else {
            pausedTimeRemaining = currentTime
        }
        
        phaseStartTime = nil
    }
    
    func resumeTimer() {
        isRunning = true
        timerState = pausedTimeRemaining <= (timerState == .work ? workTime : restTime) / 2 ? 
                    (currentTime == workTime ? .work : .rest) : 
                    (pausedTimeRemaining > restTime ? .work : .rest)
        
        // Устанавливаем новое время начала с учетом паузы
        phaseStartTime = Date()
        currentPhaseDuration = pausedTimeRemaining
        currentTime = pausedTimeRemaining
        
        startUITimer()
    }
    
    func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        phaseStartTime = nil
        pausedTimeRemaining = 0
        reset()
    }
    
    func reset() {
        timerState = .stopped
        currentRound = 1
        currentTime = workTime
        isRunning = false
        phaseStartTime = nil
        pausedTimeRemaining = 0
    }
    
    private func startUITimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.updateTimer()
        }
    }
    
    private func updateTimer() {
        guard let startTime = phaseStartTime else { return }
        
        let elapsed = Int(Date().timeIntervalSince(startTime))
        let timeRemaining = max(0, currentPhaseDuration - elapsed)
        
        currentTime = timeRemaining
        
        if timeRemaining <= 0 {
            switchPhase()
        }
    }
    
    private func switchPhase() {
        playSound()
        
        switch timerState {
        case .work:
            timerState = .rest
            currentPhaseDuration = restTime
            currentTime = restTime
            phaseStartTime = Date()
        case .rest:
            if currentRound < totalRounds {
                currentRound += 1
                timerState = .work
                currentPhaseDuration = workTime
                currentTime = workTime
                phaseStartTime = Date()
            } else {
                // Тренировка завершена
                stopTimer()
                playCompletionSound()
            }
        default:
            break
        }
    }
    
    private func handleAppWillResignActive() {
        backgroundTime = Date()
    }
    
    private func handleAppDidBecomeActive() {
        guard isRunning, let backgroundStart = backgroundTime, let phaseStart = phaseStartTime else {
            backgroundTime = nil
            return
        }
        
        // Проверяем, не закончилась ли текущая фаза или даже вся тренировка
        let totalElapsed = Int(Date().timeIntervalSince(phaseStart))
        
        if totalElapsed >= currentPhaseDuration {
            // Фаза закончилась в фоне, нужно пересчитать
            handleMissedPhases(totalElapsed: totalElapsed)
        }
        
        backgroundTime = nil
    }
    
    private func handleMissedPhases(totalElapsed: Int) {
        var remainingElapsed = totalElapsed - currentPhaseDuration
        
        // Переключаемся в следующую фазу
        playSound()
        
        while remainingElapsed > 0 && currentRound <= totalRounds {
            switch timerState {
            case .work:
                timerState = .rest
                currentPhaseDuration = restTime
                if remainingElapsed >= restTime {
                    remainingElapsed -= restTime
                    playSound()
                    if currentRound < totalRounds {
                        currentRound += 1
                        timerState = .work
                        currentPhaseDuration = workTime
                    } else {
                        stopTimer()
                        playCompletionSound()
                        return
                    }
                } else {
                    currentTime = restTime - remainingElapsed
                    phaseStartTime = Date().addingTimeInterval(-Double(remainingElapsed))
                    return
                }
            case .rest:
                if currentRound < totalRounds {
                    currentRound += 1
                    timerState = .work
                    currentPhaseDuration = workTime
                    if remainingElapsed >= workTime {
                        remainingElapsed -= workTime
                        playSound()
                        timerState = .rest
                        currentPhaseDuration = restTime
                    } else {
                        currentTime = workTime - remainingElapsed
                        phaseStartTime = Date().addingTimeInterval(-Double(remainingElapsed))
                        return
                    }
                } else {
                    stopTimer()
                    playCompletionSound()
                    return
                }
            default:
                break
            }
        }
    }
    
    private func playSound() {
        // Мощный звук смены раунда - комбинация звука и вибрации
        // Вибрация для дополнительного внимания
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        
        // Громкий трезвон - повторяем 4 раза каждые 0.4 секунды (1.6 сек общая длительность)
        let soundIDs: [SystemSoundID] = [1007, 1013, 1007, 1013] // Alternating loud sounds
        
        for (index, soundID) in soundIDs.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.4) {
                AudioServicesPlaySystemSound(soundID)
                if index % 2 == 0 {
                    // Дополнительная вибрация каждый второй звук
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                }
            }
        }
    }
    
    private func playCompletionSound() {
        // Завершение тренировки - длинный праздничный трезвон
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        
        // Последовательность звуков в течение 3 секунд
        let completionSequence: [(SystemSoundID, Double)] = [
            (1007, 0.0),   // Photosnap
            (1013, 0.3),   // Tweet  
            (1007, 0.6),   // Photosnap
            (1013, 0.9),   // Tweet
            (1007, 1.2),   // Photosnap
            (1005, 1.8),   // New Mail
            (1005, 2.1),   // New Mail
            (1005, 2.4)    // New Mail
        ]
        
        for (soundID, delay) in completionSequence {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                AudioServicesPlaySystemSound(soundID)
                if delay == 0.0 || delay == 1.2 {
                    // Вибрация в ключевые моменты
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                }
            }
        }
    }
    
    func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    var progressPercentage: Double {
        let totalTime = timerState == .work ? workTime : restTime
        guard totalTime > 0 else { return 0 }
        return Double(totalTime - currentTime) / Double(totalTime)
    }
    
    var phaseDescription: String {
        switch timerState {
        case .work:
            return "Раунд \(currentRound) из \(totalRounds)"
        case .rest:
            return "Отдых"
        case .paused:
            return "Пауза"
        case .stopped:
            return "Готов к началу"
        }
    }
} 