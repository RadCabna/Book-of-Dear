//
//  Settings.swift
//  Book of Dead
//
//  Created by Алкександр Степанов on 13.11.2025.
//

import SwiftUI

struct Settings: View {
    @AppStorage("score") var score = 0
    @AppStorage("effectsVolume") var effectsVolume: Double = 1.0
    @AppStorage("musicVolume") var musicVolume: Double = 1.0
    @ObservedObject private var soundManager = SoundManager.shared
    
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
            Image(.settingsFrame)
                .resizable()
                .scaledToFit()
                .frame(height: screenHeight*0.3)
                .overlay(
                    VStack(spacing: screenHeight*0.04) {
                        HStack {
                            Text("EFFECTS")
                                .font(Font.custom("AtomicAge-Regular", size: screenHeight*0.025))
                                .foregroundStyle(Color.white)
                                .shadow(color: Color.black, radius: 3)
                            
                            Spacer()
                            
                            CustomSlider(value: $effectsVolume)
                                .frame(width: screenWidth*0.4, height: screenHeight*0.04)
                                .onChange(of: effectsVolume) { newValue in
                                    soundManager.effectsVolume = newValue
                                }
                        }
                        HStack {
                            Text("MUSIC")
                                .font(Font.custom("AtomicAge-Regular", size: screenHeight*0.025))
                                .foregroundStyle(Color.white)
                                .shadow(color: Color.black, radius: 3)
                            
                            Spacer()
                            
                            CustomSlider(value: $musicVolume)
                                .frame(width: screenWidth*0.4, height: screenHeight*0.04)
                                .onChange(of: musicVolume) { newValue in
                                    soundManager.musicVolume = newValue
                                }
                        }
                    }
                    .padding(.horizontal, screenWidth*0.1)
                    .offset(y: screenHeight*0.04)
                )
        }
        .onAppear {
            // Синхронизируем значения из @AppStorage в SoundManager при открытии экрана настроек
            soundManager.effectsVolume = effectsVolume
            soundManager.musicVolume = musicVolume
        }
    }
}

struct CustomSlider: View {
    @Binding var value: Double // 0.0 to 1.0
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let totalHeight = geometry.size.height
            
            // Вычисляем позицию ползунка (центр ползунка)
            let thumbWidth = totalHeight*1.3 // Ширина ползунка пропорциональна высоте
            let maxThumbPosition = totalWidth - thumbWidth
            let thumbPosition = CGFloat(value) * maxThumbPosition
            
            // Граница между двумя частями должна быть строго под началом ползунка
            let dividerPosition = thumbPosition + screenHeight*0.005
            
            ZStack(alignment: .leading) {
                // Задняя часть - левая (toggleBack_1) и правая (toggleBack_2)
                HStack(spacing: 0) {
                    // Левая часть - расширяется при движении ползунка вправо
                    Image("toggleBack_1")
                        .resizable()
                        .scaledToFill()
                        .frame(width: max(0, dividerPosition), height: totalHeight*0.7)
                        .clipped()
                    
                    // Правая часть - сужается при движении ползунка вправо
                    Image("toggleBack_2")
                        .resizable()
                        .scaledToFill()
                        .frame(width: max(0, totalWidth - dividerPosition), height: totalHeight*0.7)
                        .clipped()
                }
                .mask(
                    RoundedRectangle(cornerRadius: screenHeight*0.08)
                )
                
                // Ползунок (toggleFront)
                Image("toggleFront")
                    .resizable()
                    .scaledToFit()
                    .frame(width: thumbWidth, height: totalHeight)
                    .offset(x: thumbPosition)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                isDragging = true
                                let newPosition = max(0, min(gesture.location.x, maxThumbPosition))
                                value = Double(newPosition / maxThumbPosition)
                                // Ограничиваем значение от 0 до 1
                                value = max(0, min(1, value))
                            }
                            .onEnded { _ in
                                isDragging = false
                            }
                    )
            }
        }
    }
}

#Preview {
    Settings()
}
