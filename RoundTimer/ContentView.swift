import SwiftUI

struct ContentView: View {
    @StateObject private var timerViewModel = TimerViewModel()
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Градиентный фон
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Заголовок
                                            Text("Раундовый Таймер")
                            .font(.largeTitle.weight(.bold))
                            .foregroundColor(.primary)
                    
                    // Информация о фазе
                    Text(timerViewModel.phaseDescription)
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    // Круговой прогресс-бар с таймером
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                            .frame(width: 250, height: 250)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(timerViewModel.progressPercentage))
                            .stroke(
                                timerViewModel.timerState == .work ? Color.green : Color.orange,
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 250, height: 250)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1), value: timerViewModel.progressPercentage)
                        
                        VStack {
                            Text(timerViewModel.formatTime(timerViewModel.currentTime))
                                .font(.system(size: 48, weight: .bold, design: .monospaced))
                                .foregroundColor(.primary)
                            
                            Text(timerViewModel.timerState == .work ? "РАБОТА" : "ОТДЫХ")
                                .font(.headline)
                                .foregroundColor(timerViewModel.timerState == .work ? .green : .orange)
                        }
                    }
                    
                    // Настройки времени (показываются только когда таймер остановлен)
                    if timerViewModel.timerState == .stopped {
                        VStack(spacing: 15) {
                            HStack {
                                Text("Время работы:")
                                    .font(.headline)
                                Spacer()
                                HStack {
                                    Button("-") {
                                        if timerViewModel.workTime > 30 {
                                            timerViewModel.workTime -= 30
                                        }
                                    }
                                    .buttonStyle(RoundedButtonStyle(color: .red))
                                    
                                    Text(timerViewModel.formatTime(timerViewModel.workTime))
                                        .font(.title2)
                                        .frame(width: 80)
                                    
                                    Button("+") {
                                        timerViewModel.workTime += 30
                                    }
                                    .buttonStyle(RoundedButtonStyle(color: .green))
                                }
                            }
                            
                            HStack {
                                Text("Время отдыха:")
                                    .font(.headline)
                                Spacer()
                                HStack {
                                    Button("-") {
                                        if timerViewModel.restTime > 30 {
                                            timerViewModel.restTime -= 30
                                        }
                                    }
                                    .buttonStyle(RoundedButtonStyle(color: .red))
                                    
                                    Text(timerViewModel.formatTime(timerViewModel.restTime))
                                        .font(.title2)
                                        .frame(width: 80)
                                    
                                    Button("+") {
                                        timerViewModel.restTime += 30
                                    }
                                    .buttonStyle(RoundedButtonStyle(color: .green))
                                }
                            }
                            
                            HStack {
                                Text("Количество раундов:")
                                    .font(.headline)
                                Spacer()
                                HStack {
                                    Button("-") {
                                        if timerViewModel.totalRounds > 1 {
                                            timerViewModel.totalRounds -= 1
                                        }
                                    }
                                    .buttonStyle(RoundedButtonStyle(color: .red))
                                    
                                    Text("\(timerViewModel.totalRounds)")
                                        .font(.title2)
                                        .frame(width: 40)
                                    
                                    Button("+") {
                                        timerViewModel.totalRounds += 1
                                    }
                                    .buttonStyle(RoundedButtonStyle(color: .green))
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                        .transition(.opacity)
                    }
                    
                    // Кнопки управления
                    HStack(spacing: 20) {
                        if timerViewModel.timerState == .stopped {
                            Button("Старт") {
                                timerViewModel.startTimer()
                            }
                            .buttonStyle(MainButtonStyle(color: .green))
                        } else if timerViewModel.isRunning {
                            Button("Пауза") {
                                timerViewModel.pauseTimer()
                            }
                            .buttonStyle(MainButtonStyle(color: .orange))
                        } else {
                            Button("Продолжить") {
                                timerViewModel.resumeTimer()
                            }
                            .buttonStyle(MainButtonStyle(color: .green))
                        }
                        
                        if timerViewModel.timerState != .stopped {
                            Button("Стоп") {
                                timerViewModel.stopTimer()
                            }
                            .buttonStyle(MainButtonStyle(color: .red))
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
}

// Кастомные стили для кнопок
struct MainButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2.weight(.semibold))
            .foregroundColor(.white)
            .frame(width: 120, height: 50)
            .background(color)
            .cornerRadius(25)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct RoundedButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
                                        .font(.title3.weight(.bold))
            .foregroundColor(.white)
            .frame(width: 40, height: 40)
            .background(color)
            .cornerRadius(20)
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 