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
    
    init() {
        setupAudio()
        reset()
    }
    
    private func setupAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Ошибка настройки аудио: \(error)")
        }
    }
    
    func startTimer() {
        if timerState == .stopped {
            timerState = .work
            currentTime = workTime
        }
        
        isRunning = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateTimer()
        }
    }
    
    func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        timerState = .paused
    }
    
    func resumeTimer() {
        isRunning = true
        timerState = currentTime == workTime ? .work : .rest
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateTimer()
        }
    }
    
    func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        reset()
    }
    
    func reset() {
        timerState = .stopped
        currentRound = 1
        currentTime = workTime
        isRunning = false
    }
    
    private func updateTimer() {
        if currentTime > 0 {
            currentTime -= 1
        } else {
            switchPhase()
        }
    }
    
    private func switchPhase() {
        playSound()
        
        switch timerState {
        case .work:
            timerState = .rest
            currentTime = restTime
        case .rest:
            if currentRound < totalRounds {
                currentRound += 1
                timerState = .work
                currentTime = workTime
            } else {
                // Тренировка завершена
                stopTimer()
                playCompletionSound()
            }
        default:
            break
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