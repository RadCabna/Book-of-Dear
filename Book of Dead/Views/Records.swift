//
//  Records.swift
//  Book of Dead
//
//  Created by Алкександр Степанов on 13.11.2025.
//

import SwiftUI

struct Records: View {
    @AppStorage("score") var score = 0
    @State private var recordsClaimed: [Bool] = [false, false, false, false] // Отслеживание полученных рекордов
    
    // Статистика для проверки условий
    private var totalEarnedCoins: Int {
        UserDefaults.standard.integer(forKey: "totalEarnedCoins")
    }
    
    private var bestLevelTime: Int? {
        let time = UserDefaults.standard.integer(forKey: "bestLevelTime")
        return time > 0 ? time : nil
    }
    
    private var minDamageTaken: Int {
        UserDefaults.standard.integer(forKey: "minDamageTaken")
    }
    
    private var levelsCompleted: Int {
        UserDefaults.standard.integer(forKey: "levelsCompleted")
    }
    
    // Проверка условий для каждого рекорда
    private var record1Available: Bool {
        totalEarnedCoins > 200 && !recordsClaimed[0]
    }
    
    private var record2Available: Bool {
        if let time = bestLevelTime {
            return time < 60 && !recordsClaimed[1] // Меньше минуты (60 секунд)
        }
        return false
    }
    
    private var record3Available: Bool {
        // Минимальный урон (0) - проверяем, что был пройден хотя бы один уровень без урона
        return levelsCompleted > 0 && minDamageTaken == 0 && !recordsClaimed[2]
    }
    
    private var record4Available: Bool {
        levelsCompleted >= 5 && !recordsClaimed[3]
    }
    
    var body: some View {
        ZStack {
            Image(.winBG)
                .resizable()
                .ignoresSafeArea()
            ZStack {
                HStack {
                    VStack {
                        Image(.screFrame)
                            .resizable()
                            .scaledToFit()
                            .frame(height: screenHeight*0.03)
                            .overlay(
                                Text("\(score)")
                                    .font(Font.custom("AtomicAge-Regular", size: screenHeight*0.02))
                                    .foregroundStyle(Color.text1)
                                    .offset(x: screenHeight*0.01)
                            )
                        Text("SCORE")
                            .font(Font.custom("AtomicAge-Regular", size: screenHeight*0.02))
                            .foregroundStyle(Color.white)
                            .offset(x: screenHeight*0.01)
                    }
                    Spacer()
                }
                Image(.backMenuButton)
                    .resizable()
                    .scaledToFit()
                    .frame(height: screenHeight*0.07)
                    .onTapGesture {
                        NavGuard.shared.currentScreen = .MENU
                    }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.horizontal)
            
            // Сетка рекордов: 2-2
            VStack(spacing: screenHeight*0.05) {
                // Первый ряд - 2 рекорда
                HStack(spacing: screenWidth*0.1) {
                    RecordView(
                        recordIndex: 0,
                        imageName: "record_1",
                        isAvailable: record1Available,
                        isClaimed: recordsClaimed[0],
                        onTap: { claimRecord(0) }
                    )
                    RecordView(
                        recordIndex: 1,
                        imageName: "record_2",
                        isAvailable: record2Available,
                        isClaimed: recordsClaimed[1],
                        onTap: { claimRecord(1) }
                    )
                }
                
                // Второй ряд - 2 рекорда
                HStack(spacing: screenWidth*0.1) {
                    RecordView(
                        recordIndex: 2,
                        imageName: "record_3",
                        isAvailable: record3Available,
                        isClaimed: recordsClaimed[2],
                        onTap: { claimRecord(2) }
                    )
                    RecordView(
                        recordIndex: 3,
                        imageName: "record_4",
                        isAvailable: record4Available,
                        isClaimed: recordsClaimed[3],
                        onTap: { claimRecord(3) }
                    )
                }
            }
        }
        .onAppear {
            loadRecordsState()
        }
    }
    
    private func loadRecordsState() {
        if let savedRecords = UserDefaults.standard.array(forKey: "recordsClaimed") as? [Bool] {
            recordsClaimed = savedRecords
        } else {
            recordsClaimed = [false, false, false, false]
            saveRecordsState()
        }
    }
    
    private func saveRecordsState() {
        UserDefaults.standard.set(recordsClaimed, forKey: "recordsClaimed")
    }
    
    private func claimRecord(_ index: Int) {
        guard index < recordsClaimed.count else { return }
        
        // Проверяем доступность рекорда
        var canClaim = false
        switch index {
        case 0:
            canClaim = record1Available
        case 1:
            canClaim = record2Available
        case 2:
            canClaim = record3Available
        case 3:
            canClaim = record4Available
        default:
            break
        }
        
        if canClaim {
            // Начисляем 10 монет
            score += 10
            // Помечаем рекорд как полученный
            recordsClaimed[index] = true
            saveRecordsState()
        }
    }
}

struct RecordView: View {
    let recordIndex: Int
    let imageName: String
    let isAvailable: Bool
    let isClaimed: Bool
    let onTap: () -> Void
    
    var body: some View {
        ZStack {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: screenWidth*0.3, height: screenHeight*0.2)
                .blur(radius: (isAvailable || isClaimed) ? 0 : 1) // Блюр если недоступен
                .grayscale(isClaimed ? 1.0 : 0.0) // Черно-белый если получен
                .opacity(isAvailable || isClaimed ? 1.0 : 0.5) // Полупрозрачный если недоступен
        }
        .onTapGesture {
            if isAvailable {
                onTap()
            }
        }
    }
}

#Preview {
    Records()
}
